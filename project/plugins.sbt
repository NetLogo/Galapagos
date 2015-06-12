// Comment to get more information during initialization
logLevel := Level.Warn

// The Typesafe repository
resolvers += "Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/"

// Use the Play sbt plugin for Play projects
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.3.9")

addSbtPlugin("com.typesafe.sbt" % "sbt-coffeescript" % "1.0.0")

scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-Xlint",
  "-Xfatal-warnings"
)

lazy val root = project.in(file(".")).dependsOn(sbtAutoprefixer)
lazy val sbtAutoprefixer = uri("git://github.com/matthewrennie/sbt-autoprefixer.git#ebd23db3316aa9ebaad66f251843445eda8f9994")
