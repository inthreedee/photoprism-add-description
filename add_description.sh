#!/usr/bin/env bash

###########################################################################
# This script scrapes photo descriptions from Google Photos takeout files
# and imports the descriptions into the corresponding photos in a
# Photoprism library.
#
# To use this script:
#
# 1. Download the source photo data via Google Takeout.
# 2. If not working directly on the server, download the
#    photoprism sidecar directory.
# 3. Edit the variables below to match your paths and server configuration.
# 4. Run the script.
#
# Notes:
#
# - Libraries with more than a few thousand photos can take a while;
#   The more sidecar files that have to be scanned, the longer it will take.
# - Sidecar files should be stored on an ssd for performance reasons.
# - If an API becomes available to get a photo UID from its filename,
#   that would be a much more efficient method than scanning sidecars files.
############################################################################

googleTakeoutDir="/path/to/takeout/directory"
googleAlbumDir="$googleTakeoutDir/Google Album Name"
sidecarDir="/path/to/sidecar/directory"

siteURL="https://photos.example.com"
sessionAPI="/api/v1/session"
photoAPI="/api/v1/photos"

apiUsername="admin"
apiPassword='password'

############################################################################

shopt -s globstar

# Create a new session
echo "Creating session..."
sessionID="$(curl --silent -X POST -H "Content-Type: application/json" -d "{\"username\": \"$apiUsername\", \"password\": \"$apiPassword\"}" "$siteURL$sessionAPI" 2>&1 | grep -Eo '"id":.*"' | awk -F '"' '{print $4}')"

# Clean up the session on script exit
trap 'echo "Deleting session..." & curl --silent -X DELETE -H "X-Session-ID: $sessionID" -H "Content-Type: application/json" "$siteURL$sessionAPI/$sessionID" >/dev/null' EXIT


# Scan the google takeout dir for json files
echo "Searching jsons..."
count=1
for jsonFile in "$googleAlbumDir"/**/*.json; do
    # Get the photo title (filename) from the google json file
    googleFile="$(awk -F \" '/"title":/ {print $4}' "$jsonFile")"
    description="$(awk -F \" '/"description":/ {print $4}' "$jsonFile")"
    
    # Skip this file if it has no title or description
    if [ -z "$googleFile" ] || [ -z "$description" ]; then
        continue
    fi
    
    echo "$count: Trying to match $googleFile..."

    # Find a matching file in the photoprism sidecar directory
    found=0
    for ymlFile in "$sidecarDir"/**/*.yml; do
        sidecarFile="$(basename "$ymlFile")"
        
        if [ "${sidecarFile%.*}" = "${googleFile%.*}" ]; then
            # We found a match
            echo "Match found: $sidecarFile"
            found=1

            # Get the photo's UID
            photoUID="$(awk '/UID:/ {print $2}' "$ymlFile")"

            # Send an API request to add the descriptiop to the photo
            echo "Adding to $photoUID: $description"
            curl --silent -X PUT -H "X-Session-ID: $sessionID" -H "Content-Type: application/json" -d "{\"Description\": \"$description\", \"DescriptionSrc\": \"manual\"}" "$siteURL$photoAPI/$photoUID" >/dev/null

            # Stop processing sidecar files for this json
            break
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        echo "WARNING: No match found for $googleFile!"
    fi
    
    count="$((count+1))"
done
