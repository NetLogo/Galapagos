package models.local

import
  play.api.Logger

import
  org.nlogo.{ api, nvm, tortoise },
    api.{ CompilerException, ModelReader, ModelSection, Program, WorldDimensions },
    nvm.FrontEndInterface.{ NoProcedures, ProceduresMap },
    tortoise.Compiler

case class NetLogoCompiler(dimensions: WorldDimensions = WorldDimensions(-16, 16, -16, 16),
                           program:    Program         = Program.empty(),
                           procedures: ProceduresMap   = NoProcedures) {

  def runCommand(command: String): (NetLogoCompiler, String) = {
    Logger.info(s"Compiling: ${command}")
    val strOpt = carefullyCompile(Compiler.compileCommands(command, procedures, program))
    Logger.info(s"Compiled to: ${strOpt}")
    strOpt map ((this, _)) getOrElse ((this, ""))
  }

  def runCommand(agentType: String, command: String) : (NetLogoCompiler, String) = {
    val cmd = {
      if (agentType != "observer")
        s"""|ask $agentType [
            |  $command
            |]""".stripMargin
      else
        command
    }
    runCommand(cmd)
  }

  //@ Improve later with more-dynamic selection of configs
  def apply(source: String) : (NetLogoCompiler, String) = {
    Logger.info("Beginning compilation")
    val strCompilerOpt = carefullyCompile {
      val (js, newProgram, newProcedures) = Compiler.compileProcedures(source, dimensions)
      Logger.info("No errors!")
      (NetLogoCompiler(dimensions, newProgram, newProcedures), js)
    }
    Logger.info("Compilation complete")
    strCompilerOpt getOrElse ((this, ""))
  }

  private def carefullyCompile[T](f: => T) : Option[T] = {
    try Option(f)
    catch {
      case ex: CompilerException =>
        Logger.warn(s"Execution failed: ${ex.getMessage}")
        None
      case ex: MatchError =>
        Logger.warn(s"Could not match given primitive: ${ex.getMessage}")
        None
      case ex: IllegalArgumentException =>
        Logger.warn(s"Feature not yet supported: ${ex.getMessage}")
        None
    }
  }

}

object NetLogoCompiler {

  def generateJS(source: String, dimensions: (Int, Int, Int, Int)): String = {
    val (minX, maxX, minY, maxY) = dimensions
    val (javascript, _, _)       = Compiler.compileProcedures(source, WorldDimensions(minX, maxX, minY, maxY))
    javascript
  }

  def fromNLogoFile(contents: String): (NetLogoCompiler, String) = {

    val modelMap  = ModelReader.parseModel(contents)
    val interface = modelMap(ModelSection.Interface)
    val source    = modelMap(ModelSection.Code).mkString("\n")

    val Seq(minX, maxX, minY, maxY) = 17 to 20 map { x => interface(x).toInt }
    val dimensions = WorldDimensions(minX, maxX, minY, maxY)

    NetLogoCompiler(dimensions)(source)

  }

}
