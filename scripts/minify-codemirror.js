// Minifies CodeMirror 5 and its addons in-place after `npm install`.
// CodeMirror 5 does not ship a minified bundle, but it is served directly from node_modules
// as a static asset (not bundled through Rollup), so Rollup's terser pass does not cover it.

import { readFileSync, writeFileSync } from "fs";
import { minify } from "terser";

const files = [
  "node_modules/codemirror/lib/codemirror.js",
  "node_modules/codemirror/addon/comment/comment.js",
  "node_modules/codemirror/addon/dialog/dialog.js",
  "node_modules/codemirror/addon/display/placeholder.js",
  "node_modules/codemirror/addon/hint/show-hint.js",
  "node_modules/codemirror/addon/mode/simple.js",
  "node_modules/codemirror/addon/search/search.js",
  "node_modules/codemirror/addon/search/searchcursor.js",
  "node_modules/codemirror/mode/css/css.js",
  "node_modules/codemirror/mode/javascript/javascript.js",
];

for (const file of files) {
  const source = readFileSync(file, "utf8");
  const { code } = await minify(source);
  const minFile = file.replace(/\.js$/, ".min.js");
  writeFileSync(minFile, code);
  console.log(`minified ${file} -> ${minFile}`);
}
