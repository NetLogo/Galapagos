import sbt._
import Keys._
import PlayProject._

object ApplicationBuild extends Build {

    val appName         = "HeadlessNL"
    val appVersion      = "1.0-SNAPSHOT"

    val appDependencies = Seq(
      "asm" % "asm-all" % "3.3.1",
      "log4j" % "log4j" % "1.2.16",
      "org.picocontainer" % "picocontainer" % "2.13.6",
      "org.nlogo" % "NetLogo" % "5.0.1" from "http://ccl.northwestern.edu/netlogo/5.0.1/NetLogo.jar",
      "com.imaginea" %% "socket.io.play" % "0.0.3-SNAPSHOT"
    )

    val main = PlayProject(appName, appVersion, appDependencies, mainLang = SCALA).settings(
      resolvers += "Sonatype Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"
    )

}
