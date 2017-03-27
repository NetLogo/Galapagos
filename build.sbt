import com.typesafe.sbt.web.Import.WebKeys.webJarsDirectory

import org.nlogo.PlayScrapePlugin.credentials.{ fromCredentialsProfile, fromEnvironmentVariables }

name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.11.8"

scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-language:_",
  "-Xlint",
  "-Ywarn-value-discard",
  "-Xfatal-warnings"
)

lazy val root = (project in file(".")).enablePlugins(PlayScala, org.nlogo.PlayScrapePlugin)

val tortoiseVersion = "1.0-8d76feb"

libraryDependencies ++= Seq(
  filters,
  "org.nlogo" % "tortoise" % tortoiseVersion,
  "org.nlogo" % "netlogowebjs" % tortoiseVersion,
  cache,
  "com.typesafe.akka" %% "akka-testkit" % "2.4.14" % "test",
  "org.scalatestplus" %% "play" % "1.4.0" % "test"
)

libraryDependencies ++= Seq(
  "org.webjars" % "chosen" % "1.3.0",
  "org.webjars.npm" % "filesaver.js" % "0.1.1",
  "org.webjars.npm" % "mousetrap" % "1.5.3",
  "org.webjars.bower" % "google-caja" % "6005.0.0",
  "org.webjars" % "highcharts" % "5.0.6",
  "org.webjars" % "jquery" % "3.1.1",
  "org.webjars" % "markdown-js" % "0.5.0-1",
  "org.webjars" % "ractive" % "0.7.3",
  "org.webjars" % "codemirror" % "5.13.2",
  "org.webjars.bower" % "github-com-highcharts-export-csv" % "1.4.3"
)

resolvers += bintray.Opts.resolver.repo("netlogo", "TortoiseAux")

resolvers += bintray.Opts.resolver.repo("netlogo", "NetLogoHeadless")

resolvers += Resolver.file("Local repo", file(System.getProperty("user.home") + "/.ivy2/local"))(Resolver.ivyStylePatterns)

GalapagosAssets.settings

// Used in Prod
pipelineStages ++= Seq(digest)

// Also used in Dev mode
pipelineStages in Assets ++= Seq(autoprefixer)

fork in Test := false

includeFilter in autoprefixer := Def.setting {
  val webJarDir     = (webJarsDirectory in Assets).value.getPath
  val testWebJarDir = (webJarsDirectory in TestAssets).value.getPath
  new FileFilter {
    override def accept(file: java.io.File) = {
      file.getName.endsWith(".css") && ! (file.getPath.contains(webJarDir) || file.getPath.contains(testWebJarDir))
    }
  }
}.value

routesGenerator := InjectedRoutesGenerator

scrapeRoutes ++= Seq(
  "/humans.txt",
  "/info",
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
  "/web"
  )

scrapeDelay := 120

def isTravis: Boolean = System.getenv("TRAVIS") == "true"

def travisBranch: String =
  if (System.getenv("TRAVIS_PULL_REQUEST") != "false")
    "PR-" + System.getenv("TRAVIS_PULL_REQUEST")
  else
    System.getenv("TRAVIS_BRANCH")

scrapePublishCredential := (Def.settingDyn {
  if (isTravis)
    Def.setting { fromEnvironmentVariables }
  else
    // Requires setting up a credentials profile, ask Robert for more details
    Def.setting { fromCredentialsProfile("nlw-admin") }
}).value

scrapePublishBucketID := (Def.settingDyn {
  val branchDeploy = Map("master" -> "netlogo-web-prod-content")

  if (isTravis)
    Def.setting { branchDeploy.get(travisBranch) }
  else
    Def.setting { branchDeploy.get("master") }
}).value

scrapePublishDistributionID := (Def.settingDyn {
  val branchPublish = Map("master" -> "E3AIHWIXSMPCAI")

  if (isTravis)
    Def.setting { branchPublish.get(travisBranch) }
  else
    Def.setting { branchPublish.get("master") }
}).value

scrapeAbsoluteURL := Some("netlogoweb.org")
