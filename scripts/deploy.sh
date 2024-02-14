#!/bin/bash

# Deploy Galapagos to a specific AWS S3 bucket and invalidate its CloudFront distribution.

# Check for necessary command line tools and exit if not installed.
for cmd in sbt aws cp; do
  command -v "$cmd" >/dev/null 2>&1 || { echo >&2 "This script requires $cmd but it's not installed. Aborting."; exit 1; }
done

# Verify that the script parameters are passed.
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 s3-target-bucket/target-folder DISTRIBUTION_ID url/path" >&2
  exit 1
fi

# Variables
S3_BUCKET_PATH="s3://$1"
CLOUDFRONT_DISTRIBUTION_ID="$2"
ABSOLUTE_URL="$3"

# Inform the user of the operations being performed.
echo "Deploying to ${S3_BUCKET_PATH} with base URL set to ${ABSOLUTE_URL}"

# Set the absolute URL for sbt scraping.
sbt "set scrapeAbsoluteURL := Some(\"$ABSOLUTE_URL\")" clean scrapePlay

# Copy assets to the target directory.
echo "Copying assets to the target directory..."
cp -Rv public/{modelslib,nt-modelslib} target/play-scrape/assets/
cp node_modules/chosen-js/chosen-sprite*.png target/play-scrape/assets/chosen-js/

# Sync files to S3 bucket.
echo "Syncing assets to ${S3_BUCKET_PATH}..."
aws s3 sync ./target/play-scrape "$S3_BUCKET_PATH" --delete --acl public-read \
  --exclude "*" --include "*.*" --exclude "*.html"

echo "Syncing HTML files to ${S3_BUCKET_PATH} with correct content type..."
aws s3 sync ./target/play-scrape "$S3_BUCKET_PATH" --delete --acl public-read \
  --exclude "*" --include "*[!.]*" --include "*.html" --content-type "text/html; charset=utf-8"

# Invalidate CloudFront distribution.
echo "Creating CloudFront invalidation for distribution ID ${CLOUDFRONT_DISTRIBUTION_ID}..."
aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" --paths "/*"

echo "Deployment complete."
