resolvers += Resolver.url(
  "bintray-sbt-plugin-releases",
   url("http://dl.bintray.com/content/sbt/sbt-plugin-releases"))(
       Resolver.ivyStylePatterns)

// excluding the sl4fj-nop dependency prevents a warning about
// having two different slf4j implementations on the classpath,
// since sbt-js-engine depends on slf4j-simple - ST 6/3/15
addSbtPlugin(
  "me.lessis" % "bintray-sbt" % "0.1.2"
    exclude ("org.slf4j", "slf4j-nop")
)
