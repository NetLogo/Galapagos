// Comment to get more information during initialization
logLevel := Level.Warn

// The Typesafe repository
resolvers += "Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/"

// Use the Play sbt plugin for Play projects
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.4.2")

addSbtPlugin("com.typesafe.sbt" % "sbt-coffeescript" % "1.0.0")

addSbtPlugin("org.scalastyle" %% "scalastyle-sbt-plugin" % "0.7.0")

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

resolvers += Resolver.url(
  "play-scraper",
    url("http://dl.bintray.com/content/netlogo/play-scraper"))(
        Resolver.ivyStylePatterns)

addSbtPlugin("org.nlogo" % "play-scraper" % "0.6.2")
