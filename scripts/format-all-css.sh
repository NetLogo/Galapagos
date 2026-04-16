#!/bin/bash

# Formats all CSS files in public/stylesheets/ in-place using format-css.py.
# Usage (from repo root): ./scripts/format-all-css.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CSS_DIR="$SCRIPT_DIR/../public/stylesheets"

for f in "$CSS_DIR"/*.css; do
  # Skip the embedded-font file — base64 blobs don't benefit from formatting
  [[ "$(basename "$f")" == "netlogo-fonts.css" ]] && continue
  tmp=$(mktemp)
  python3 "$SCRIPT_DIR/format-css.py" "$f" > "$tmp"
  mv "$tmp" "$f"
  echo "formatted: $f"
done
