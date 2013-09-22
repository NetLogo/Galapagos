package models.local

import
  play.api.Logger

import
  org.nlogo.{ api, nvm, tortoise },
    api.{ CompilerException, Program, WorldDimensions },
    nvm.FrontEndInterface.{ NoProcedures, ProceduresMap },
    tortoise.Compiler

case class NetLogoCompiler(program: Program = Program.empty(), procedures: ProceduresMap = NoProcedures) {
  
  def apply(command: String) = {
    Logger.info(s"Compiling: ${command}")
    val strOpt = carefullyCompile(Compiler.compileCommands(command, procedures, program))
    Logger.info(s"Compiled to: ${strOpt}")
    strOpt map ((_, this)) getOrElse (("", this))
  }

  def apply(agentType: String, command: String) : (String, NetLogoCompiler) = {
    val cmd = {
      if (agentType != "observer")
        s"""|ask $agentType [
            |  $command
            |]""".stripMargin
      else
        command
    }
    apply(cmd)
  }

  //@ Improve later with more-dynamic selection of configs
  def generateModelState(source: String, dimensions: WorldDimensions) : (String, NetLogoCompiler) = {
    Logger.info("Beginning compilation")
    val strCompilerOpt = carefullyCompile {
      val (js, newProgram, newProcedures) = Compiler.compileProcedures(source, dimensions)
      Logger.info("No errors!")
      (js, NetLogoCompiler(newProgram, newProcedures))
    }
    Logger.info("Compilation complete")
    strCompilerOpt getOrElse (("", this))
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
