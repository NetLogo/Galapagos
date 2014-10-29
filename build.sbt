name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.11.2"

scalacOptions += "-language:_"

lazy val root = (project in file(".")).enablePlugins(PlayScala)

libraryDependencies ++= Seq(
  "org.nlogo" % "tortoise" % "0.1-5c1b79d"
)

libraryDependencies ++= Seq(
  "org.webjars" % "chosen" % "1.1.0-1",
  "org.webjars" % "highcharts" % "4.0.4",
  "org.webjars" % "underscorejs" % "1.7.0",
  "org.webjars" % "underscore.string" % "2.3.3",
  "org.webjars" % "jquery" % "2.1.1",
  "org.webjars" % "ace" % "01.08.2014",
  "org.webjars" % "mousetrap" % "1.4.6",
  "org.webjars" % "markdown-js" % "0.5.0-1"
)

resolvers += bintray.Opts.resolver.repo("netlogo", "Tortoise")

resolvers += bintray.Opts.resolver.repo("netlogo", "NetLogoHeadless")

resolvers += Resolver.file("Local repo", file(System.getProperty("user.home") + "/.ivy2/local"))(Resolver.ivyStylePatterns)

SetupConfiguration.settings

bintray.Plugin.bintrayResolverSettings
