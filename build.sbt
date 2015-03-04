name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.11.5"

scalacOptions += "-language:_"

lazy val root = (project in file(".")).enablePlugins(PlayScala)

libraryDependencies ++= Seq(
  "org.nlogo" % "tortoise" % "0.1-ffc9633",
  "com.typesafe.play" %% "play-cache" % "2.3.8",
  "com.typesafe.akka" %% "akka-testkit" % "2.3.8" % "test",
  "org.scalatestplus" %% "play" % "1.2.0" % "test"
)

libraryDependencies ++= Seq(
  "org.webjars" % "chosen" % "1.3.0",
  "org.webjars" % "highcharts" % "4.0.4",
  "org.webjars" % "underscorejs" % "1.8.2",
  "org.webjars" % "underscore.string" % "2.3.3",
  "org.webjars" % "jquery" % "2.1.3",
  "org.webjars" % "ace" % "01.08.2014",
  "org.webjars" % "mousetrap" % "1.4.6",
  "org.webjars" % "markdown-js" % "0.5.0-1",
  "org.webjars" % "ractive" % "0.6.1",
  "org.webjars" % "codemirror" % "5.0"
)

resolvers += bintray.Opts.resolver.repo("netlogo", "TortoiseAux")

resolvers += bintray.Opts.resolver.repo("netlogo", "NetLogoHeadless")

resolvers += Resolver.file("Local repo", file(System.getProperty("user.home") + "/.ivy2/local"))(Resolver.ivyStylePatterns)

SetupConfiguration.settings
