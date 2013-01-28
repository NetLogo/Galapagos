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
    "org.picocontainer" % "picocontainer" % "2.13.6",
    "org.nlogo" % "NetLogoHeadless" % "5.1.0-SNAPSHOT" from
      "http://ccl.northwestern.edu/devel/NetLogoHeadless-3b4f9377.jar"
  )

  val moreSettings = Seq[Setting[_]](
    scalacOptions in ThisBuild += "-feature"
  )

  val main = play.Project(appName, appVersion, appDependencies).settings(
    moreSettings ++ ObtainResources.settings: _*)

}
