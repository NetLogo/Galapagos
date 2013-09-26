import
  sbt._,
    Keys._

import
  java.io.{ File, PrintWriter }

// Initializing configuration file

object SetupConfiguration {

  val configFile = new File("./conf/application.conf")

  val checkConfig = TaskKey[Unit]("check-config", "Check to see that the configuration file exists; if not, generate one")
  val genConfig   = TaskKey[Unit]("gen-config",   "Generate a new configuration file from user responses")

  val settings = Seq[Setting[_]](
    checkConfig := { if (!configFile.exists) generateConfig() },
    genConfig   := { generateConfig() },
    compile in Compile <<= (compile in Compile).dependsOn(checkConfig)
  )

  private def generateConfig() {

    import scala.language.reflectiveCalls

    def using[T <: { def close() }, U](t: => T)(f: T => U) : U = {
      val that = t
      try     f(that)
      finally that.close()
    }

    configFile.delete()
    val configMap = gatherConfigMap()
    configFile.createNewFile()

    using(new PrintWriter(configFile)) {
      w => configMap foreach { case (k, v) => w.println(s"$k=$v") }
    }

  }

  private def gatherConfigMap() : Map[String, String] = {

    val paramsAndDefaults = Seq(
      ("application.secret",            "the application's private encryption key",                                      None),
      ("application.remote.killswitch", "if \"true\", stops Teletortoise rooms from running models when they are empty", Option("true"))
    )

    val pureDefaults = Map(
      "application.defaultEncoding" -> "UTF-8",
      "application.langs"           -> "\"en\"",
      "logger.root"                 -> "ERROR",
      "logger.play"                 -> "INFO",
      "logger.application"          -> "DEBUG"
    )

    promptForConfiguration {
      () => paramsAndDefaults.foldLeft(pureDefaults) {
        case (acc, (key, desc, default)) => acc + (key -> queryUntilValid(key, desc, default))
      }
    }

  }

  def promptForConfiguration[T](f: () => T) : T = {

    print("""
            |**********
            |
            |Please input your desired values for the following configuration keys...
            |
            |""".stripMargin)

    val configuration = f()

    print("""
            |Configuration complete!
            |
            |**********
            |""".stripMargin)

    configuration

  }

  @scala.annotation.tailrec
  def queryUntilValid(key: String, desc: String, default: Option[String]) : String = {

    println()
    println("%s (%s) [DEFAULT: %s]".format(key, desc, default getOrElse "<none>"))
    val response = readLine()

    if (!response.isEmpty)
      response
    else if (!default.isEmpty)
      default.get
    else {
      print("A value is required for " + key)
      queryUntilValid(key, desc, default)
    }

  }

}
