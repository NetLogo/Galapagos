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
  "play-scraper"     at "https://dl.cloudsmith.io/public/netlogo/play-scraper/maven/"
, "sbt-coffeescript" at "https://dl.cloudsmith.io/public/netlogo/sbt-coffeescript/maven/"
)

addSbtPlugin("com.typesafe.play" %  "sbt-plugin"            % "2.6.21")
addSbtPlugin("org.scalastyle"    %% "scalastyle-sbt-plugin" % "1.0.0")
addSbtPlugin("com.typesafe.sbt"  %  "sbt-mocha"             % "1.1.2")
addSbtPlugin("com.typesafe.sbt"  %  "sbt-digest"            % "1.1.4")
addSbtPlugin("org.nlogo"         %  "sbt-coffeescript"      % "1.0.4")
addSbtPlugin("org.nlogo"         %  "play-scraper"          % "0.8.1")
addSbtPlugin("com.timushev.sbt"  %  "sbt-updates"           % "0.3.4")
