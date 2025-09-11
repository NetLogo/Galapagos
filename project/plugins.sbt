// Comment to get more information during initialization
logLevel := Level.Warn

resolvers ++= Seq(
  "play-scraper-workaround" at "https://dl.cloudsmith.io/public/netlogo/play-scraper-workaround/maven/"
)

addSbtPlugin("com.typesafe.play" % "sbt-plugin"   % "2.9.7")
addSbtPlugin("com.github.sbt"    % "sbt-digest"   % "2.1.0")
addSbtPlugin("org.nlogo"         % "play-scraper" % "1.3.0-cddbd6d")
addSbtPlugin("com.timushev.sbt"  % "sbt-updates"  % "0.5.0")

// Conflict with a common dependency of Play/Twirl.  No updates in a long time, so maybe time to switch.  -Jeremy B June
// 2025
// addSbtPlugin("org.scalastyle"    %% "scalastyle-sbt-plugin" % "1.0.0")
