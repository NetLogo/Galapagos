#!/bin/bash

# Requires NetTango and Galapagos repo clones be in the same parent directory.

# You should also `yarn link` in `../NetTango` and then `yarn link nettango` in this repo
# to make sure the local copy is used when updated/recompiled in sbt/Play outside of this script.

# After doing `sbt run`, run this script from the root of the Galapagos repo
# `./scripts/nettango-package.sh` and it will update the NetTango script in `target/` with your
# NetTango repo work in progress.

# Play copies all resources into the `target/` directory on `run`, so this is a workaround.  Other
# workarounds would've affected how files were presented for production (as opposed to just
# development work), so hey.

cd ../NetTango
yarn build # shoud generate the "development" version with un-minified file modules via `eval()` for easy debugging
cd ../Galapagos

cp ../NetTango/nettango.js ./target/web/public/main/nettango/nettango.js
cp ../NetTango/nettango.css ./target/web/public/main/nettango/nettango.css

# Once this is all setup, the workflow becomes:

# 0. Have Galapagos sbt running the development server - `sbt run`
# 1. Make a change in NetTango.
# 2. Run this script to copy everything into Galapagos.
# 3. Refresh the Galapagos page in web browser to see the NetTango changes (maybe without cache, just in case).
# 4. Return to 1 and repeat as needed.
