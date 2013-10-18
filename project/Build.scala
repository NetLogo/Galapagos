import
  sbt._,
    Keys._

import
  play.Project._

object ApplicationBuild extends Build {

  val appName         = "Teletortoise"
  val appVersion      = "1.0-SNAPSHOT"

  val appDependencies = Seq(
    "asm" % "asm-all" % "3.3.1", // Necessary evil
    "org.nlogo" % "NetLogoHeadless" % "5.1.0-SNAPSHOT-1e3f423" from
      "http://ccl.northwestern.edu/devel/NetLogoHeadless-1e3f423.jar",
    "org.scalaz" %% "scalaz-core" % "7.0.3",
    "org.webjars" %% "webjars-play" % "2.2.0",
    "org.webjars" % "chosen" % "0.9.12",
    "org.webjars" % "underscorejs" % "1.5.1",
    "org.webjars" % "underscore.string" % "2.3.0",
    "org.webjars" % "jquery" % "1.10.2-1",
    "org.webjars" % "ace" % "07.31.2013",
    "org.webjars" % "mousetrap" % "1.3",
    "org.webjars" % "bootstrap" % "2.3.2"
  )

  val moreSettings = Seq[Setting[_]](
    scalacOptions += "-language:_",
    scalaVersion := "2.10.2"
  )

  val main = play.Project(appName, appVersion, appDependencies).settings(
    moreSettings ++ ObtainResources.settings ++ SetupConfiguration.settings: _*
  )

}
