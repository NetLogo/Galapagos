package models.local

import
  play.api.Logger

import
  org.nlogo.{ api, nvm, tortoise },
    api.{ CompilerException, Program },
    nvm.CompilerInterface.{ NoProcedures, ProceduresMap },
    tortoise.Compiler

case class NetLogoCompiler(program: Program = Program.empty(), procedures: ProceduresMap = NoProcedures) {

  def apply(command: String) = {
    val strOpt = carefullyCompile(Compiler.compileCommands(command, procedures, program))
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
  def generateModelState : (String, NetLogoCompiler) = {
    val strCompilerOpt = carefullyCompile {
      val (js, newProgram, newProcedures) = NetLogoModels.compileLife
      (js, NetLogoCompiler(newProgram, newProcedures))
    }
    strCompilerOpt getOrElse (("", this))
  }

  private def carefullyCompile[T](f: => T) : Option[T] = {
    try Option(f)
    catch {
      case ex: CompilerException =>
        Logger.warn(s"Execution failed: ${ex.getMessage}")
        None
      case ex: MatchError =>
        Logger.warn(s"Could not make given primitive: ${ex.getMessage}")
        None
    }
  }

}

object NetLogoModels {

  def compileLife =
    Compiler.compileProcedures(
      """|patches-own [living? live-neighbors]
        |
        |to setup
        |  clear-all
        |  ask patches [ celldeath ]
        |  ask patch  0  0 [ cellbirth ]
        |  ask patch -1  0 [ cellbirth ]
        |  ask patch  0 -1 [ cellbirth ]
        |  ask patch  0  1 [ cellbirth ]
        |  ask patch  1  1 [ cellbirth ]
        |end
        |
        |to cellbirth set living? true  set pcolor green end
        |to celldeath set living? false set pcolor blue end
        |
        |to go
        |  ask patches [
        |    set live-neighbors count neighbors with [living?] ]
        |  ask patches [
        |    ifelse live-neighbors = 3
        |      [ cellbirth ]
        |      [ if live-neighbors != 2
        |        [ celldeath ] ] ]
        |end
        |""".stripMargin, -20, 20, -20, 20)

}
