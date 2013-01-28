package models.local

import
  play.api.Logger

import
  org.nlogo.{ api, nvm, tortoise },
    api.{ CompilerException, Program },
    nvm.CompilerInterface.{ ProceduresMap, NoProcedures },
    tortoise.Compiler

object NetLogoCompiler {

  var program: Program = Program.empty()
  var procedures: ProceduresMap = NoProcedures

  def apply(command: String) =
    carefullyCompile(Compiler.compileCommands(
      command, oldProcedures = procedures, program = program))

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
  def generateModelState = carefullyCompile{
    val (js, newProgram, newProcedures) =
      Compiler.compileProcedures(
        """|patches-own [ living? live-neighbors ]
           |
           |to setup
           |  clear-all
           |  ask patches [set living? false]
           |  ask patch  0  0 [ set living? true set pcolor white ]
           |  ask patch -1  0 [ set living? true set pcolor white ]
           |  ask patch  0 -1 [ set living? true set pcolor white ]
           |  ask patch  0  1 [ set living? true set pcolor white ]
           |  ask patch  1  1 [ set living? true set pcolor white ]
           |end
           |
           |to cellbirth set living? true  set pcolor white end
           |to celldeath set living? false set pcolor black end
           |
           |to go
           |  ask patches [
           |    set live-neighbors count neighbors with [living?] ]
           |  ask patches [ ifelse live-neighbors = 3 [ cellbirth ] [ if live-neighbors != 2 [ celldeath ] ] ]
           |end
           |""".stripMargin, -6, 6, -6, 6)
    program = newProgram
    procedures = newProcedures
    js
  }

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
