import sbt._
import Keys._
import PlayProject._

object ApplicationBuild extends Build {

  val appName         = "Teletortoise"
  val appVersion      = "1.0-SNAPSHOT"

  val appDependencies = Seq(
    "asm" % "asm-all" % "3.3.1", // Necessary evil
    "org.picocontainer" % "picocontainer" % "2.13.6",
    //"org.nlogo" % "NetLogo" % "5.0.2" from "http://ccl.northwestern.edu/netlogo/5.0.2/NetLogo.jar"
    "org.nlogo" % "NetLogoHeadless" % "5.0.3-SNAPSHOT" from "file:///Users/headb/Development/NetLogo/nl.modelruns/headless/target/NetLogoHeadless.jar"
  )

  val resolverSettings = Seq[Setting[_]]()

  val main = PlayProject(appName, appVersion, appDependencies, mainLang = SCALA).settings(
    resolverSettings ++ ObtainResources.settings: _*)

}
