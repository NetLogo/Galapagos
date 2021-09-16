import org.nlogo.PlayScrapePlugin.credentials.{ fromCredentialsProfile, fromEnvironmentVariables }
import com.typesafe.sbt.web.Import.WebKeys.webTarget
import com.typesafe.sbt.web.{ Compat, PathMapping }
import com.typesafe.sbt.web.pipeline.Pipeline
import sbt.io.Path.relativeTo

import scala.sys.process.Process

name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.12.8"

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

lazy val root = (project in file(".")).enablePlugins(PlayScala, org.nlogo.PlayScrapePlugin)

val tortoiseVersion = "1.0-2b4702f"

libraryDependencies ++= Seq(
  ehcache,
  filters,
  guice,
  "org.nlogo" % "compilerjvm" % tortoiseVersion,
  "org.nlogo" % "netlogowebjs" % tortoiseVersion,
  "com.typesafe.play" %% "play-iteratees" % "2.6.1",
  "com.typesafe.akka" %% "akka-testkit" % "2.5.15" % "test",
  "org.scalatestplus.play" %% "scalatestplus-play" % "3.1.2" % "test"
)

libraryDependencies ++= Seq(
  "org.webjars" % "markdown-js" % "0.5.0-1",
  "org.webjars.bower" % "google-caja" % "6005.0.0"
)

resolvers ++= Seq(
  "compilerjvm"     at "https://dl.cloudsmith.io/public/netlogo/tortoise/maven/"
, "netlogowebjs"    at "https://dl.cloudsmith.io/public/netlogo/tortoise/maven/"
, "netlogoheadless" at "https://dl.cloudsmith.io/public/netlogo/netlogo/maven/"
, "play-scraper"    at "https://dl.cloudsmith.io/public/netlogo/play-scraper/maven/"
)

unmanagedResourceDirectories in Assets += baseDirectory.value / "node_modules"

lazy val nodeModules = Def.task[File] {
  baseDirectory.value / "node_modules"
}

lazy val yarnIntegrity = Def.task[File] {
  baseDirectory.value / "node_modules" / ".yarn-integrity"
}

lazy val packageJson = Def.task[File] {
  baseDirectory.value / "package.json"
}

lazy val yarnInstall = taskKey[Unit]("Runs `yarn install` from within SBT")
yarnInstall := {
  val log = streams.value.log
  val nodeDirectory = nodeModules.value
  val nodeExists = nodeDirectory.exists && nodeDirectory.isDirectory && nodeDirectory.list.length > 0
  val integrityFile = yarnIntegrity.value
  if (!nodeExists || !integrityFile.exists || integrityFile.olderThan(packageJson.value))
    Process(Seq("yarn", "install", "--ignore-optional"), baseDirectory.value).!(log)
  ()
}

lazy val coffeelint = taskKey[Unit]("lint coffeescript files in Galapagos")
coffeelint := {
  yarnInstall.value
  val log = streams.value.log
  Process(Seq("yarn", "coffeelint"), baseDirectory.value).!(log)
  ()
}

(compile in Compile) := ((compile in Compile).dependsOn(yarnInstall)).value


lazy val bundle = taskKey[Pipeline.Stage]("Bundle script files using Rollup")

includeFilter in bundle := "*.js" || "*.js.map"
excludeFilter in bundle := HiddenFileFilter

bundle := Def.task {
  val streamsValue = streams.value
  val inputDir = webTarget.value / "rollup" / "sync-rollup" / "main"
  val outputDir = webTarget.value / "rollup" / "main"
  val scriptsDir = "javascripts" + java.io.File.separator
  val include = (includeFilter in bundle).value
  val exclude = (excludeFilter in bundle).value

  (inputMappings: Seq[PathMapping]) => {

    // Partition input mappings into files we want to bundle and files we just want to ignore and pass through to the
    // next pipeline stage. - David D. 7/2021
    val (filesToBundle, ignoredFiles) = inputMappings.partition({
      case (file, relativePath) =>
        relativePath.startsWith(scriptsDir) && !file.isDirectory && !exclude.accept(file) && include.accept(file)
    })

    // Run the function only if files have changed since the last run - David D. 7/2021
    val runBundler = FileFunction.cached(streamsValue.cacheDirectory / "rollup", FilesInfo.hash) { _ =>

      // Rollup needs its inputs in a folder, not a list of random files, so we sync the input files of this pipeline
      // stage into a temporary folder, where Rollup can easily access them. - David D. 7/2021
      SbtWeb.syncMappings(
        Compat.cacheStore(streamsValue, "sync-rollup"),
        filesToBundle,
        inputDir
      )

      val nodeEnv = if (PlayDevMode.isDevMode) "development" else "production"
      val inputsCount = filesToBundle.count(f => !"*.js.map".accept(f._1))

      streamsValue.log.info(s"Rollup: Bundling ${inputsCount} script file(s) in ${nodeEnv} mode ...")
      val bundlerOutput = runRollup(baseDirectory.value, inputDir, outputDir, streamsValue, nodeEnv)
      streamsValue.log.info(s"Rollup: Done bundling.")

      bundlerOutput.toSet
    }

    val bundledFiles = runBundler(filesToBundle.map(_._1).toSet) pair relativeTo(outputDir)
    bundledFiles ++ ignoredFiles
  }

}.dependsOn(yarnInstall).value

def runRollup(baseDirectory: File, inputDir: File, outputDir: File, streams: TaskStreams, nodeEnv: String): Seq[File] = {
  Process(
    Seq("./node_modules/.bin/rollup",
      "--config", "rollup.config.js",
      // Custom arguments with the 'config-' prefix are passed through to rollup.config.js. - David D. 7/2021
      "--config-sourceDir", inputDir.getPath,
      "--config-targetDir", outputDir.relativeTo(baseDirectory).get.getPath,
      // Rollup prints all messages, including info to STDERR, but SBT would then display everything as errors and
      // clutter the output. The --silent flag causes Rollup to output only errors, which we still want to see.
      // - David D. 7/2021
      "--silent"
    ),
    baseDirectory,
    "NODE_ENV" -> nodeEnv
  ).!(streams.log)

  (outputDir ** ("*.js" || "*.js.map")).get
}

// Don't digest chunks, because they are `import`ed by filename in other script files. Besides, they already contain
// a digest in their filename anyway, so there is no need to do it twice.
// - David D. 7/2021
excludeFilter in digest := "*.chunk.js"

// We want to run the bundler in different modes in production and development. Unfortunately pipelineStages don't
// provide a way to run hooks only in development (`pipelineStages in Assets` are run in prod *and* dev). So we need to
// use a playRunHook to detect if we're in development mode (`sbt run`). - David D. 7/2021
PlayKeys.playRunHooks += PlayDevMode()

// Used in Dev and Prod
pipelineStages in Assets ++= Seq(bundle)

// Used in Prod
pipelineStages ++= Seq(digest)


fork in Test := false

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
