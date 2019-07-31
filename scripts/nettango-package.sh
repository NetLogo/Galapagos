#!/bin/bash

# Requires NetTango and Galapagos repo clones be in the same parent directory.

# Run: `pub run build_runner watch --release --output web:build` in your `../NetTango` directory,
# and you can run this script to copy the generated files into Galapagos for immediate use.

# You should also `yarn link` in `../NetTango/package` and then `yarn link nettango` here
# to make sure the local copy is used when updated/recompiled in sbt/Play outside of this script.

# After doing `sbt run`, run this script from the root of the Galapagos repo
# `./scripts/nettango-package.sh` and it will update the NetTango script in `target/` with your
# NetTango repo work in progress.

# Play copies all resources into the `target/` directory, so this is a workaround.  Other
# workarounds would've affected how files were presented for production (as opposed to just
# development work), so hey.

cat ../NetTango/build/dart/ntango.dart.js ../NetTango/web/js/ntango.js > ../NetTango/package/ntango.js
cp ../NetTango/web/css/ntango.css ../NetTango/package/ntango.css

cp ../NetTango/package/ntango.js ./target/web/public/main/nettango/ntango.js
cp ../NetTango/package/ntango.css ./target/web/public/main/nettango/ntango.css

# To get NetTango built without munging all the variable names, add the below (uncommented) to
# `build.yaml` in the root of the NetTango directory.

# targets:
#   $default:
#     builders:
#       build_web_compilers|entrypoint:
#         options:
#           dart2js_args:
#           - --fast-startup

# Once this is all setup, the workflow becomes:

# 0. Have Galapagos sbt running the development server - `sbt run`
# 1. Make a change in NetTango.
# 2. Wait for the dart compiler watcher to finish compiling.
# 3. Run this script to copy everything into Galapagos.
# 4. Refresh the Galapagos page in web browser to see the NetTango changes (maybe without cache, just in case).
# 5. Return to 1 and repeat as needed.
