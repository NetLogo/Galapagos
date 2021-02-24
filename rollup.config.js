import sourcemaps from 'rollup-plugin-sourcemaps';
import { terser } from "rollup-plugin-terser";
import fs from "fs";
import path from "path";

export default ({ "config-sourceDir": sourceDir, "config-targetDir": targetDir }) => {

  const isDevelopment = process.env.NODE_ENV === "development"
  const inputDir = `${sourceDir}/javascripts`;
  const outputDir = `${targetDir}/javascripts`;

  // In development the `sourcemaps` plugin allows Rollup to read sourcemaps produced by sbt-coffeescript.
  // In production, we use `terser` to minify the bundle.
  const plugins = isDevelopment ? [sourcemaps()] : [terser()]

  return [
    // All files in the '/pages' directory are considered bundle entry points.
    pagesConfig(fs.readdirSync(path.join(inputDir, "pages")).map(page => `pages/${page}`)),

    // Create a full bundle containing everything for the standalone mode of '/simulation'
    standaloneBundleConfig("pages/simulation.js"),

    // Files imported in tests are transformed to commonjs
    ...testInputsConfig([
      "beak/tortoise-utils.js"
    ]),
  ];

  // Generates a bundle configuration for a list of page entries.
  function pagesConfig(entryFiles) {
    const bundleInputs = {};
    for (let file of entryFiles) {
      const [path, extension] = splitExtension(file)
      bundleInputs[path] = `${inputDir}/${path}${extension}`;
    }

    return {
      input: bundleInputs,
      output: {
        dir: outputDir,
        format: "esm",
        sourcemap: isDevelopment,
        chunkFileNames: "[name]-[hash].chunk.js"
      },
      plugins,
      context: "this",
    };
  }

  // Generates a bundle configuration for a full standalone bundle with the given entry.
  function standaloneBundleConfig(entryFile) {
    const [path, extension] = splitExtension(entryFile)
    return {
      input: `${inputDir}/${path}${extension}`,
      output: {
        file: `${outputDir}/${path}.bundle${extension}`,
        sourcemap: isDevelopment,
      },
      plugins,
      context: "this",
    };
  }

  // Generates a bundle configuration for the given test entry files.
  function testInputsConfig(entryFiles) {
    // Unfortunately, SBT-Web always runs the production pipelineStages before running tests, so there is no way to
    // produce testBundles only when testing. But we can at least avoid bundling test inputs in development mode.
    if (isDevelopment) return [];

    const bundleInputs = {};
    for (let file of entryFiles) {
      const [path, extension] = splitExtension(file)
      bundleInputs[path] = `${inputDir}/${path}${extension}`;
    }

    return [{
      input: bundleInputs,
      output: {
        format: "cjs",
        dir: outputDir,
      },
    }];
  }
}

// Splits a path into a file name and an extension. An extension is anything after the last '.'.
// For example: splitExtension("foo/bar.js") = ["foo/bar", ".js"].
function splitExtension(path) {
  const splitAt = path.lastIndexOf(".");
  if (splitAt === -1) return [path, ""];
  return [path.substring(0, splitAt), path.substring(splitAt)]
}
