package models.local

import
  play.api.Logger

import
  org.nlogo.{ api, tortoise },
    api.CompilerException,
    tortoise.Compiler

object NetLogoCompiler {

  def apply(command: String) = carefullyCompile(Compiler.compileCommands(command))

  def apply(agentType: String, command: String) : String = {
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

  //@ Improve later
  def generateModelState = carefullyCompile(Compiler.compileProcedures(""))

  private def carefullyCompile(f: => String) : String = {
    try f
    catch {
      case ex: CompilerException =>
        Logger.warn(s"Execution failed: ${ex.getMessage}")
        ""
      case ex: MatchError =>
        Logger.warn(s"Could not make given primitive: ${ex.getMessage}")
        ""
    }
  }

}
