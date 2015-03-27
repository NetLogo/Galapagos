// Comment to get more information during initialization
logLevel := Level.Warn

// The Typesafe repository
resolvers += "Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/"

// Use the Play sbt plugin for Play projects
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.3.8")

addSbtPlugin("com.typesafe.sbt" % "sbt-coffeescript" % "1.0.0")

// get warnings when compiling build definition
scalacOptions += "-feature"

lazy val root = project.in(file(".")).dependsOn(sbtAutoprefixer)
lazy val sbtAutoprefixer = uri("git://github.com/matthewrennie/sbt-autoprefixer")
