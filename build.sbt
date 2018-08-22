import org.nlogo.PlayScrapePlugin.credentials.{ fromCredentialsProfile, fromEnvironmentVariables }

name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.12.6"

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

val tortoiseVersion = "1.0-3ebb85d"

libraryDependencies ++= Seq(
  ehcache,
  filters,
  guice,
  "org.nlogo" % "compilerjvm" % tortoiseVersion,
  "org.nlogo" % "netlogowebjs" % tortoiseVersion,
  "com.typesafe.play" %% "play-iteratees" % "2.6.1",
  "com.typesafe.akka" %% "akka-testkit" % "2.5.14" % "test",
  "org.scalatestplus.play" %% "scalatestplus-play" % "3.1.2" % "test"
)

libraryDependencies ++= Seq(
  "org.webjars" % "chosen" % "1.8.7",
  "org.webjars.bower" % "filesaver" % "1.3.3",
  "org.webjars.npm" % "mousetrap" % "1.6.1",
  "org.webjars.bower" % "google-caja" % "6005.0.0",
  "org.webjars" % "highcharts" % "6.1.1",
  "org.webjars" % "jquery" % "3.3.1",
  "org.webjars" % "markdown-js" % "0.5.0-1",
  "org.webjars.npm" % "ractive" % "0.9.9",
  "org.webjars.npm" % "codemirror" % "5.39.2"
)

resolvers += Resolver.bintrayRepo("netlogo", "TortoiseAux")

resolvers += Resolver.bintrayRepo("netlogo", "NetLogoHeadless")

// Used in Prod
pipelineStages ++= Seq(digest)

fork in Test := false

routesGenerator := InjectedRoutesGenerator

scrapeRoutes ++= Seq(
  "/humans.txt",
  "/docs/authoring",
  "/docs/differences",
  "/docs/faq",
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
  "/ntango",
  "/ntango-play",
  "/web"
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
    "master"  -> "netlogo-web-prod-content",
    "staging" -> "netlogo-web-staging-content"
  )

  if (isJenkins)
    Def.setting { branchDeploy.get(jenkinsBranch) }
  else
    Def.setting { branchDeploy.get("master") }
}).value

scrapePublishDistributionID := (Def.settingDyn {
  val branchPublish = Map(
    "master"  -> "E3AIHWIXSMPCAI",
    "staging" -> "E360I3EFLPUZR0"
  )

  if (isJenkins)
    Def.setting { branchPublish.get(jenkinsBranch) }
  else
    Def.setting { branchPublish.get("master") }
}).value

scrapeAbsoluteURL := (Def.settingDyn {
  if (isJenkins && jenkinsBranch == "staging")
    Def.setting { Some("staging.netlogoweb.org") }
  else
    Def.setting { Some("netlogoweb.org") }
}).value
