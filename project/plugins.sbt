// Comment to get more information during initialization
logLevel := Level.Warn

scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-Xfatal-warnings"
)

resolvers ++= Seq(
  "play-scraper" at "https://dl.cloudsmith.io/public/netlogo/play-scraper/maven/"
)

addSbtPlugin("com.typesafe.play" %  "sbt-plugin"            % "2.9.7")
// Conflict with a common dependency of Play/Twirl.  No updates in a long time, so maybe time to switch.  -Jeremy B June
// 2025
// addSbtPlugin("org.scalastyle"    %% "scalastyle-sbt-plugin" % "1.0.0")
addSbtPlugin("com.github.sbt"    %  "sbt-digest"            % "2.1.0")
addSbtPlugin("org.nlogo"         %  "play-scraper"          % "1.1.0")
addSbtPlugin("com.timushev.sbt"  %  "sbt-updates"           % "0.5.0")
