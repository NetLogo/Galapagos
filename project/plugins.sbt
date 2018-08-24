// Comment to get more information during initialization
logLevel := Level.Warn

// Use the Play sbt plugin for Play projects
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.6.18")

addSbtPlugin("com.typesafe.sbt" % "sbt-coffeescript" % "1.0.2")

addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "1.0.0")

addSbtPlugin("com.typesafe.sbt" % "sbt-mocha" % "1.1.2")

addSbtPlugin("com.typesafe.sbt" % "sbt-digest" % "1.1.4")

scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-Xfatal-warnings"
)

resolvers += Resolver.bintrayIvyRepo("netlogo", "play-scraper")

addSbtPlugin("org.nlogo" % "play-scraper" % "0.8.1")

addSbtPlugin("com.timushev.sbt" % "sbt-updates" % "0.3.4")
