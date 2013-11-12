import
  sbt._,
    Keys._

import
  play.Project._

object ApplicationBuild extends Build {

  val appName         = "Galapagos"
  val appVersion      = "1.0-SNAPSHOT"

  // NetLogo ought to declare its own dependencies, but sadly it
  // doesn't, so we need to explicitly list asm ourselves
  val nlDependencies = Seq(
    "org.nlogo" % "NetLogoHeadless" % "5.1.0-SNAPSHOT-cf45a582" from
      "http://ccl.northwestern.edu/devel/NetLogoHeadless-cf45a582.jar",
    "asm" % "asm-all" % "3.3.1"
  )

  val scalaDependencies = Seq(
    "org.json4s" %% "json4s-native" % "3.1.0",
    "org.scalaz" %% "scalaz-core" % "7.0.3",
    "org.webjars" %% "webjars-play" % "2.2.0"
  )

  val jsDependencies = Seq(
    "org.webjars" % "chosen" % "0.9.12",
    "org.webjars" % "underscorejs" % "1.5.1",
    "org.webjars" % "underscore.string" % "2.3.0",
    "org.webjars" % "jquery" % "1.10.2-1",
    "org.webjars" % "ace" % "07.31.2013",
    "org.webjars" % "mousetrap" % "1.3",
    "org.webjars" % "bootstrap" % "2.3.2",
    "org.webjars" % "qunit" % "1.11.0"
  )

  val allDependencies =
    nlDependencies ++ scalaDependencies ++ jsDependencies

  val moreSettings = Seq[Setting[_]](
    scalacOptions += "-language:_",
    scalaVersion := "2.10.2"
  )

  val main = play.Project(appName, appVersion, allDependencies).settings(
    moreSettings ++ ObtainResources.settings ++ SetupConfiguration.settings: _*
  )

}
