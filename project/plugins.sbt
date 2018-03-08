// Comment to get more information during initialization
logLevel := Level.Warn

// Use the Play sbt plugin for Play projects
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.6.3")

addSbtPlugin("com.typesafe.sbt" % "sbt-coffeescript" % "1.0.0")

addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "0.8.0")

addSbtPlugin("com.typesafe.sbt" % "sbt-mocha" % "1.1.0")

addSbtPlugin("com.typesafe.sbt" % "sbt-digest" % "1.1.2")

scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-Xlint",
  "-Xfatal-warnings"
)

resolvers += Resolver.url(
  "play-scraper",
    url("http://dl.bintray.com/content/netlogo/play-scraper"))(
        Resolver.ivyStylePatterns)

addSbtPlugin("org.nlogo" % "play-scraper" % "0.7.6")

libraryDependencies += "org.im4java" % "im4java" % "1.4.0" // only used for asset generation
