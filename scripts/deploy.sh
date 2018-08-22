#!/bin/bash

# This script can be used to deploy Galapagos to a non-standard AWS location
# AWS credentials will need to be configured for this script to work
# Usage (from root of the Galapgos repo): ./scripts/deploy.sh s3-target-bucket/target-folder DISTRIBUTION_ID url/path
# Example: ./scripts/deploy.sh netlogo-web-experiments-content/nettango E2TDYOH5TZH83M experiments.netlogoweb.org/nettango

sbt "set scrapeAbsoluteURL := Some(\"$3\")" clean scrapePlay
cp -Rv public/modelslib/ target/play-scrape/assets/modelslib
cp target/web/web-modules/main/webjars/lib/chosen/chosen-sprite*.png target/play-scrape/assets/lib/chosen/
aws s3 sync ./target/play-scrape s3://$1 --delete --acl public-read --exclude "*" --include "*.*" --exclude "*.html"
aws s3 sync ./target/play-scrape s3://$1 --delete --acl public-read --exclude "*" --include "*[!.]*" --include "*.html" --content-type "text/html; charset=utf-8"
aws cloudfront create-invalidation --distribution-id $2 --paths "/*"
