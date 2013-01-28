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
      """
        |turtles-own [next steps]
        |
        |to setup
        |  clear-all
        |  __ask-sorted patches [
        |    if random 100 < 20
        |      [ set pcolor yellow ] ]
        |  crt 50
        |  __ask-sorted turtles [
        |    set color white
        |    setxy random-xcor random-ycor
        |    set size 3
        |    set next 1
        |  ]
        |end
        |
        |to go
        |  __ask-sorted turtles
        |    [ ifelse steps > 0
        |        [ set steps steps - 1 ]
        |        [ action
        |          wiggle ]
        |      fd 1 ]
        |end
        |
        |to wiggle
        |  rt random 50
        |  lt random 50
        |end
        |
        |to action
        |  ifelse next = 1
        |    [ searchforchip ]
        |    [ ifelse next = 2
        |      [ findnewpile ]
        |      [ ifelse next = 3
        |        [ putdownchip ]
        |        [ getaway ] ] ]
        |end
        |
        |to searchforchip
        |  if pcolor = yellow
        |    [ set pcolor black
        |      set color orange
        |      set steps 20
        |      set next 2 ]
        |end
        |
        |to findnewpile
        |  if pcolor = yellow
        |    [ set next 3 ]
        |end
        |
        |to putdownchip
        |  if pcolor = black
        |   [ set pcolor yellow
        |     set color white
        |     set steps 20
        |     set next 4 ]
        |end
        |
        |to getaway
        |  if pcolor = black
        |    [ set next 1 ]
        |end
        |""".stripMargin, -20, 20, -20, 20)

}
