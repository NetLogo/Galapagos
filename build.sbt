playScalaSettings

name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.10.2"

scalacOptions += "-language:_"

// NetLogo ought to declare its own dependencies, but sadly it
// doesn't, so we need to explicitly list asm ourselves
libraryDependencies ++= Seq(
  "org.nlogo" % "NetLogoHeadless" % "5.1.0-SNAPSHOT-cf45a582" from
    "http://ccl.northwestern.edu/devel/NetLogoHeadless-cf45a582.jar",
  "asm" % "asm-all" % "3.3.1"
)

libraryDependencies ++= Seq(
  "org.json4s" %% "json4s-native" % "3.1.0",
  "org.scalaz" %% "scalaz-core" % "7.0.3",
  "org.webjars" %% "webjars-play" % "2.2.0"
)

libraryDependencies ++= Seq(
  "org.webjars" % "chosen" % "0.9.12",
  "org.webjars" % "underscorejs" % "1.5.1",
  "org.webjars" % "underscore.string" % "2.3.0",
  "org.webjars" % "jquery" % "1.10.2-1",
  "org.webjars" % "ace" % "07.31.2013",
  "org.webjars" % "mousetrap" % "1.3",
  "org.webjars" % "bootstrap" % "2.3.2"
)

ObtainResources.settings

SetupConfiguration.settings
