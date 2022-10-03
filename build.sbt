import org.nlogo.PlayScrapePlugin
import org.nlogo.PlayScrapePlugin.credentials.{ fromCredentialsProfile, fromEnvironmentVariables }
import com.typesafe.sbt.web.Import.WebKeys.webTarget
import com.typesafe.sbt.web.{ Compat, PathMapping }
import com.typesafe.sbt.web.pipeline.Pipeline
import sbt.io.Path.relativeTo
import sbt.IO

import java.nio.file.{ Files, StandardCopyOption }

import scala.sys.process.Process

name    := "Galapagos"
version := "1.0-SNAPSHOT"

scalaVersion := "2.12.17"
scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-language:_",
  // Scala 2.12.4 produces warnings for unused imports, but Play generates
  // files as part of compilation that have unused imports, so we have to
  // disable these warnings for now.  -JMB July 2017
  "-Xlint:-unused",
  "-Ywarn-value-discard",
  "-Xfatal-warnings"
)

lazy val root = (project in file("."))
  .enablePlugins(PlayScala, PlayScrapePlugin)
  .settings(
    // Disable NPM node modules
    Assets / JsEngineKeys.npmNodeModules := Nil,
    TestAssets / JsEngineKeys.npmNodeModules := Nil
  )

val tortoiseVersion = "1.0-7d9715c"

resolvers ++= Seq(
  "compilerjvm"     at "https://dl.cloudsmith.io/public/netlogo/tortoise/maven/"
, "netlogowebjs"    at "https://dl.cloudsmith.io/public/netlogo/tortoise/maven/"
, "netlogoheadless" at "https://dl.cloudsmith.io/public/netlogo/netlogo/maven/"
, "play-scraper"    at "https://dl.cloudsmith.io/public/netlogo/play-scraper/maven/"
)

libraryDependencies ++= Seq(
  ehcache
, filters
, guice
// these guice imports are temporary to support Java 17 with Play 2.8.16.  They should be removed once a later version
// of Play properly references them.  -Jeremy B September 2022
, "com.google.inject"            % "guice"                % "5.1.0"
, "com.google.inject.extensions" % "guice-assistedinject" % "5.1.0"
, "org.nlogo" % "compilerjvm"  % tortoiseVersion
, "org.nlogo" % "netlogowebjs" % tortoiseVersion
// ideally these would be moved to `package.json`, but they aren't on npm at these exact versions, so here they stay.
// -Jeremy B September 2022
, "org.webjars"       % "markdown-js" % "0.5.0-1"
, "org.webjars.bower" % "google-caja" % "6005.0.0"
// akka-testkit must match the akka version used by Play -Jeremy B September 2022
, "com.typesafe.akka"      %% "akka-testkit"       % "2.6.19" % Test
, "org.scalatestplus.play" %% "scalatestplus-play" % "5.1.0"  % Test
)

evictionErrorLevel := Level.Warn

Assets / unmanagedResourceDirectories += baseDirectory.value / "node_modules"

def runYarn(log: Logger, runDir: File, args: Seq[String], env: (String, String)*): Unit = {
  val yarnArgs = Seq("yarn") ++ args
  Process(yarnArgs, runDir, env:_*).!(log)
  ()
}

lazy val yarnInstall = taskKey[Unit]("runs `yarn install` if necessary based on current repo status")
yarnInstall := {
  val log           = streams.value.log
  val nodeDir       = baseDirectory.value / "node_modules"
  val nodeExists    = nodeDir.exists && nodeDir.isDirectory && nodeDir.list.length > 0
  val integrityFile = nodeDir / ".yarn-integrity"
  val packageJson   = baseDirectory.value / "package.json"
  if (!nodeExists || !integrityFile.exists || integrityFile.olderThan(packageJson)) {
    runYarn(log, baseDirectory.value, Seq("install", "--ignore-optional"))
  }
}

lazy val coffeeInputDirectory  = Def.setting[File] { baseDirectory.value / "app" / "assets" / "javascripts" }
lazy val coffeeOutputDirectory = Def.setting[File] { baseDirectory.value / "target" / "coffee-output" / "main" }

lazy val coffee = taskKey[Unit]("compile coffeescript files")
coffee := Def.task {
  val log               = streams.value.log
  val baseDir           = baseDirectory.value
  val coffeeInputDir    = coffeeInputDirectory.value
  val coffeeChangedDir  = baseDirectory.value / "target" / "coffee-changed"
  val coffeeOutputDir   = coffeeOutputDirectory.value
  val coffeeInputPath   = coffeeInputDir.asPath
  val coffeeChangedPath = coffeeChangedDir.asPath
  val coffeeOutputPath  = coffeeOutputDir.asPath

  // get our file paths straight
  val inOutFiles = (coffeeInputDir ** ("*.coffee")).get.map( (sourceFile) => {
    val relativePath     = coffeeInputPath.relativize(sourceFile.asPath)
    val changedFile      = coffeeChangedPath.resolve(relativePath).toFile
    val fileName         = sourceFile.getName.split("\\.").dropRight(1).mkString(".")
    val relativeParent   = relativePath.getParent
    val outputParentPath = if (relativeParent == null) {
      coffeeOutputPath
    } else {
      coffeeOutputPath.resolve(relativePath.getParent)
    }
    val outputFile = outputParentPath.resolve(s"$fileName.js").toFile
    (sourceFile, changedFile, outputFile)
  })

  // get only the coffee files that have changed
  val changedFiles = inOutFiles.filter({ case (sourceFile, _, outputFile) =>
    !outputFile.exists || outputFile.olderThan(sourceFile)
  })

  // compile the coffee files if necessary.
  if (changedFiles.length == 0) {
    log.info("No changes found in CoffeeScript files.")
  } else {
    log.info(s"Compiling ${changedFiles.length} changed CoffeeScript file(s).")
    // put the changed coffee files into a temp directory, so we can compile them while maintaining their relative paths.
    IO.delete(coffeeChangedDir)
    changedFiles.foreach({ case (sourceFile, changedFile, _) =>
      Files.createDirectories(changedFile.getParentFile.asPath)
      Files.copy(sourceFile.toPath, changedFile.toPath, StandardCopyOption.COPY_ATTRIBUTES, StandardCopyOption.REPLACE_EXISTING)
    })
    runYarn(
      log,
      baseDir,
      Seq("coffee", "--compile", "--map", "--output", coffeeOutputPath.toString, coffeeChangedPath.toString)
    )
  }

  // then copy all the non-coffee script files, too
  (coffeeInputDir ** ("*.js")).get.foreach( (sourceFile) => {
    val sourcePath = sourceFile.asPath
    val outputPath = coffeeInputPath.relativize(sourcePath)
    IO.copyFile(sourcePath.toFile, coffeeOutputPath.resolve(outputPath).toFile)
  })

}.dependsOn(yarnInstall).value

lazy val coffeelint = taskKey[Unit]("lint coffeescript files")
coffeelint := Def.task {
  runYarn(
    streams.value.log,
    baseDirectory.value,
    Seq("coffeelint", "-f", "coffeelint.json", coffeeInputDirectory.value.toString)
  )
}.dependsOn(yarnInstall).value

lazy val testInputDirectory  = Def.setting[File] { baseDirectory.value / "test" / "assets" / "javascripts" }
lazy val testOutputDirectory = Def.setting[File] { baseDirectory.value / "target" / "coffee-output" / "test" }

lazy val mochaTest = taskKey[Unit]("run mocha js tests")
mochaTest := Def.task {
  val log = streams.value.log
  log.info("Running mocha JS tests")
  IO.delete(testOutputDirectory.value)
  runYarn(
    log,
    baseDirectory.value,
    Seq("coffee", "--compile", "--map", "--output", testOutputDirectory.value.toString, testInputDirectory.value.toString)
  )
  runYarn(
    log,
    baseDirectory.value,
    Seq("mocha", "--recursive", s"${testOutputDirectory.value.toString}/**/*.js")
  )
}.dependsOn(coffee).value

lazy val bundleDirectory = Def.setting[File] { baseDirectory.value / "target" / "rollup" }

lazy val bundle = taskKey[Pipeline.Stage]("full coffeescript build and bundle with rollup as pipeline")
bundle / includeFilter := "*.coffee" || "*.js"
bundle / excludeFilter := HiddenFileFilter
bundle := Def.task {
  val streamsValue    = streams.value
  val baseDir         = baseDirectory.value
  val scriptsDir      = "javascripts" + java.io.File.separator
  val include         = (bundle / includeFilter).value
  val exclude         = (bundle / excludeFilter).value
  val coffeeOutputDir = coffeeOutputDirectory.value
  val bundleDir       = bundleDirectory.value.relativeTo(baseDir).get
  val nodeEnv         = if (PlayDevMode.isDevMode) "development" else "production"

  (inputMappings: Seq[PathMapping]) => {

    // Partition input mappings into files we want to bundle and files we just want to ignore and pass through to the
    // next pipeline stage. - David D. 7/2021
    val (outputMappings, ignoredFiles) = inputMappings.partition({
      case (file, relativePath) =>
        relativePath.startsWith(scriptsDir) && !file.isDirectory && !exclude.accept(file) && include.accept(file)
    })

    // Run the function only if files have changed since the last run - David D. 7/2021
    val runBundler = FileFunction.cached(streamsValue.cacheDirectory / "rollup", FilesInfo.hash) { _ =>
      IO.delete(bundleDir)
      runYarn(
        streamsValue.log,
        baseDir,
        Seq("rollup", "--config", "rollup.config.js",
          // Custom arguments with the 'config-' prefix are passed through to rollup.config.js. - David D. 7/2021
          "--config-sourceDir", coffeeOutputDir.getPath,
          "--config-targetDir", bundleDir.getPath,
          // Rollup prints all messages, including info to STDERR, but SBT would then display everything as errors and
          // clutter the output. The --silent flag causes Rollup to output only errors, which we still want to see.
          // - David D. 7/2021
          "--silent"
        ),
        "NODE_ENV" -> nodeEnv
      )
      (bundleDir ** ("*.js" || "*.js.map")).get.toSet
    }

    val bundledFiles: Seq[PathMapping] = runBundler(outputMappings.map(_._1).toSet) pair relativeTo(bundleDir)
    bundledFiles ++ ignoredFiles
  }
}.dependsOn(coffee).value

// Don't digest chunks, because they are `import`ed by filename in other script files. Besides, they already contain
// a digest in their filename anyway, so there is no need to do it twice.
// - David D. 7/2021
digest / excludeFilter := "*.chunk.js"

// We want to run the bundler in different modes in production and development. Unfortunately pipelineStages don't
// provide a way to run hooks only in development (`pipelineStages in Assets` are run in prod *and* dev). So we need to
// use a playRunHook to detect if we're in development mode (`sbt run`). - David D. 7/2021
PlayKeys.playRunHooks += PlayDevMode()

// Used in Dev and Prod
Assets / pipelineStages ++= Seq(bundle)

// Used in Prod
pipelineStages ++= Seq(digest)

Test / javaOptions ++= Seq(
  "--add-exports=java.base/sun.security.x509=ALL-UNNAMED"
, "--add-opens=java.base/sun.security.ssl=ALL-UNNAMED"
)

Test / test := (Test / test).dependsOn(mochaTest).value

Test / fork := true

routesGenerator := InjectedRoutesGenerator

scrapeRoutes ++= Seq(
  "/humans.txt",
  "/docs/authoring",
  "/docs/differences",
  "/docs/faq",
  "/docs/attributions",
  "/whats-new",
  "/model/list.json",
  "/model/statuses.json",
  "/netlogo-engine.js",
  "/netlogo-agentmodel.js",
  "/tortoise-compiler.js",
  "/tortoise-compiler.js.map",
  "/server-error",
  "/not-found",
  "/robots.txt",
  "/standalone",
  "/launch",
  "/web",
  "/nettango-builder",
  "/nettango-player",
  "/nettango-player-standalone",
  "/ntango-build",
  "/ntango-play",
  "/ntango-play-standalone"
  )

scrapeDelay := 120

def isJenkins: Boolean = Option(System.getenv("JENKINS_HOME")).nonEmpty

def jenkinsBranch: String =
  if (Option(System.getenv("CHANGE_TARGET")).isEmpty)
    System.getenv("BRANCH_NAME")
  else
    "PR-" + System.getenv("CHANGE_ID") + "-" + System.getenv("CHANGE_TARGET")

scrapePublishCredential := (Def.settingDyn {
  if (isJenkins)
    Def.setting { fromEnvironmentVariables }
  else
    // Requires setting up a credentials profile, ask Robert for more details
    Def.setting { fromCredentialsProfile("nlw-admin") }
}).value

scrapePublishBucketID := (Def.settingDyn {
  val branchDeploy = Map(
    "production" -> "netlogo-web-prod-content",
    "master"     -> "netlogo-web-staging-content"
  )

  if (isJenkins)
    Def.setting { branchDeploy.get(jenkinsBranch) }
  else
    Def.setting { branchDeploy.get("production") }
}).value

scrapePublishDistributionID := (Def.settingDyn {
  val branchPublish = Map(
    "production" -> "E3AIHWIXSMPCAI",
    "master"     -> "E360I3EFLPUZR0"
  )

  if (isJenkins)
    Def.setting { branchPublish.get(jenkinsBranch) }
  else
    Def.setting { branchPublish.get("production") }
}).value

scrapeAbsoluteURL := (Def.settingDyn {
  if (isJenkins && jenkinsBranch == "master")
    Def.setting { Some("staging.netlogoweb.org") }
  else
    Def.setting { Some("netlogoweb.org") }
}).value
