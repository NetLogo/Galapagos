sbt clean scrapePlay
cp -Rv public/modelslib/ target/play-scrape/assets/modelslib
cp target/web/web-modules/main/webjars/lib/chosen/chosen-sprite*.png target/play-scrape/assets/lib/chosen/
aws s3 sync ./target/play-scrape s3://netlogo-web-experiments-content/nettango --delete --acl public-read --exclude "*" --include "*.*" --exclude "*.html"
aws s3 sync ./target/play-scrape s3://netlogo-web-experiments-content/nettango --delete --acl public-read --exclude "*" --include "*[!.]*" --include "*.html" --content-type "text/html; charset=utf-8"
aws cloudfront create-invalidation --distribution-id E2TDYOH5TZH83M --paths "/*"
