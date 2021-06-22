#!/bin/bash

# This script can be used to deploy Galapagos to a non-standard AWS location
# AWS credentials will need to be configured for this script to work.  See the
# AWS command line tools docs for how to do that.

# Usage (from root of the Galapgos repo):
# ./scripts/deploy.sh s3-target-bucket/target-folder DISTRIBUTION_ID url/path

# Example deploying to experiments site in subfolder /nettango/:
# ./scripts/deploy.sh netlogo-web-experiments-content/nettango E2TDYOH5TZH83M experiments.netlogoweb.org/nettango

# For reference, if there is an emergency, these commands can be run to deploy
# to staging or production in the situation where Jenkins is down or otherwise
# cannot be used to deploy.
# ./scripts/deploy.sh netlogo-web-staging-content E360I3EFLPUZR0 staging.netlogoweb.org
# ./scripts/deploy.sh netlogo-web-prod-content E3AIHWIXSMPCAI netlogoweb.org

sbt "set scrapeAbsoluteURL := Some(\"$3\")" clean scrapePlay
cp -Rv public/modelslib/ target/play-scrape/assets/
cp -Rv public/nt-modelslib/ target/play-scrape/assets/
cp node_modules/chosen-js/chosen-sprite*.png target/play-scrape/assets/chosen-js/
aws s3 sync ./target/play-scrape s3://$1 --delete --acl public-read --exclude "*" --include "*.*" --exclude "*.html"
aws s3 sync ./target/play-scrape s3://$1 --delete --acl public-read --exclude "*" --include "*[!.]*" --include "*.html" --content-type "text/html; charset=utf-8"
aws cloudfront create-invalidation --distribution-id $2 --paths "/*"
