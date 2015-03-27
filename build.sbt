import com.typesafe.sbt.web.Import.WebKeys.webJarsDirectory

name := "Galapagos"

version := "1.0-SNAPSHOT"

scalaVersion := "2.11.7"

scalacOptions ++= Seq(
  "-encoding", "UTF-8",
  "-deprecation",
  "-unchecked",
  "-feature",
  "-language:_",
  "-Xlint",
  "-Ywarn-value-discard",
  "-Xfatal-warnings"
)

lazy val root = (project in file(".")).enablePlugins(PlayScala)

val tortoiseVersion = "0.1-0aff5c0"

libraryDependencies ++= Seq(
  "org.nlogo" % "tortoise" % tortoiseVersion,
  "org.nlogo" % "netlogowebjs" % tortoiseVersion,
  cache,
  "com.typesafe.akka" %% "akka-testkit" % "2.3.11" % "test",
  "org.scalatestplus" %% "play" % "1.4.0-M3" % "test"
)

libraryDependencies ++= Seq(
  "org.webjars" % "chosen" % "1.3.0",
  "org.webjars.npm" % "filesaver.js" % "0.1.1",
  "org.webjars" % "highcharts" % "4.1.6",
  "org.webjars" % "jquery" % "2.1.4",
  "org.webjars" % "mousetrap" % "1.4.6",
  "org.webjars" % "markdown-js" % "0.5.0-1",
  "org.webjars" % "ractive" % "0.7.1",
  "org.webjars" % "codemirror" % "5.4"
)

resolvers += bintray.Opts.resolver.repo("netlogo", "TortoiseAux")

resolvers += bintray.Opts.resolver.repo("netlogo", "NetLogoHeadless")

resolvers += Resolver.file("Local repo", file(System.getProperty("user.home") + "/.ivy2/local"))(Resolver.ivyStylePatterns)

pipelineStages in Assets += autoprefixer

fork in Test := false

includeFilter in autoprefixer := Def.setting {
  val webJarDir     = (webJarsDirectory in Assets).value.getPath
  val testWebJarDir = (webJarsDirectory in TestAssets).value.getPath
  new FileFilter {
    override def accept(file: java.io.File) = {
      file.getName.endsWith(".css") && ! (file.getPath.contains(webJarDir) || file.getPath.contains(testWebJarDir))
    }
  }
}.value

routesGenerator := InjectedRoutesGenerator
