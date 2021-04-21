import org.nlogo.PlayScrapePlugin.credentials.{ fromCredentialsProfile, fromEnvironmentVariables }
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

val tortoiseVersion = "1.0-280f3c7"

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

(compile in Compile) := ((compile in Compile).dependsOn(yarnInstall)).value

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
