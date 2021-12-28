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

lazy val root = (project in file(".")).enablePlugins(PlayScala)

val tortoiseVersion = "1.0-dafaeda"

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
  "org.webjars.npm" % "jscolor-picker" % "2.0.4",
  "org.webjars" % "chosen" % "1.8.7",
  "org.webjars.bowergithub.eligrey" % "filesaver.js" % "2.0.0",
  "org.webjars.npm" % "mousetrap" % "1.6.1",
  "org.webjars.bower" % "google-caja" % "6005.0.0",
  "org.webjars" % "highcharts" % "7.0.1",
  "org.webjars" % "jquery" % "3.3.1",
  "org.webjars" % "markdown-js" % "0.5.0-1",
  "org.webjars.npm" % "ractive" % "0.9.9",
  "org.webjars.npm" % "codemirror" % "5.42.2",
  "org.webjars.npm" % "synchrodecoder" % "1.0.2",
  "org.webjars.npm" % "localforage" % "1.7.3"
)

resolvers ++= Seq(
  "compilerjvm"     at "https://dl.cloudsmith.io/public/netlogo/tortoise/maven/"
, "netlogowebjs"    at "https://dl.cloudsmith.io/public/netlogo/tortoise/maven/"
, "netlogoheadless" at "https://dl.cloudsmith.io/public/netlogo/netlogo/maven/"
)

unmanagedResourceDirectories in Assets += baseDirectory.value / "node_modules"

// Used in Prod
pipelineStages ++= Seq(digest)

fork in Test := false

routesGenerator := InjectedRoutesGenerator

def isJenkins: Boolean = Option(System.getenv("JENKINS_HOME")).nonEmpty

def jenkinsBranch: String =
  if (Option(System.getenv("CHANGE_TARGET")).isEmpty)
    System.getenv("BRANCH_NAME")
  else
    "PR-" + System.getenv("CHANGE_ID") + "-" + System.getenv("CHANGE_TARGET")
