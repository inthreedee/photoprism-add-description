# photoprism-add-description
*A quick and dirty script to transfer photo descriptions from Google Photos json files to matching Photoprism photos*

Google Photos can potentially store lower quality photos.  If you have and upload full quality originals to Photoprism but still want to import photo descriptions from Google Photos, this script can help.  Once a library has been fully transferred, this script will scrape the necessary data from a Google Takeout of a library and use it to add photo descriptions to the Photoprism library.

## To use this script:

1. Download the desired photos via Google Takeout.
2. If not working directly on the server, download the photoprism sidecar directory.
3. Edit the variables at the top of the script to match your paths and server configuration.
4. Run the script.

## What it does:
1. It scans the json files in the Google Takeout directory, pulling out the title and description fields.
2. It scans the yml files in the Photoprism sidecar directory, attempting to find a matching filename.
3. Once it finds a match, it pulls the photo's UID from the yml file.
4. An API request is sent to the server to add the description to that photo UID.

## Notes:

- Libraries with more than a few thousand photos can take a while; the more sidecar files that have to be scanned, the longer it will take.
- Sidecar files should be stored on an ssd for performance reasons.
- If an API becomes available to get a photo UID from its filename, that would be a much more efficient method than scanning sidecars files.
