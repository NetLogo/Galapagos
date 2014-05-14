package models.local

import
  org.nlogo.{ api, compile, core, nvm, tortoise },
    api.{ CompilerException, model, Program },
      model.ModelReader,
    compile.front.FrontEnd,
    core.Model,
    nvm.{ DefaultParserServices, FrontEndInterface },
      FrontEndInterface.{ NoProcedures, ProceduresMap },
    tortoise.Compiler

import
  play.api.Logger

case class NetLogoCompiler(model:      Model,
                           program:    Program       = Program.empty(),
                           procedures: ProceduresMap = NoProcedures) {

  def runCommand(command: String): (NetLogoCompiler, String) = {
    Logger.info(s"Compiling: $command")
    val strOpt = carefullyCompile(Compiler.compileCommands(command, procedures, program))
    Logger.info(s"Compiled to: $strOpt")
    val js = strOpt getOrElse ""
    (this, js)
  }

  def runReporter(reporter: String): (NetLogoCompiler, String) = {
    Logger.info(s"Compiling: $reporter")
    val strOpt = carefullyCompile(Compiler.compileReporter(reporter, procedures, program))
    Logger.info(s"Compiled to: $strOpt")
    val js = strOpt getOrElse ""
    (this, js)
  }

  def runCommand(agentType: String, command: String): (NetLogoCompiler, String) = {
    val cmd =
      if (agentType != "observer")
        s"""|ask $agentType [
            |  $command
            |]""".stripMargin
      else
        command
    runCommand(cmd)
  }

  def compileWidget(widget: core.Widget) (implicit program: api.Program, procedures: ProceduresMap): String = {
    import WidgetJS._
    widget match {
      case b: core.Button => b.toJS
      case s: core.Slider => s.toJS
      case s: core.Switch => s.toJS
      case m: core.Monitor => m.toJS
      case o: core.Output => o.toJS
      case v: core.View => v.toJS
      case p: core.Plot => p.toJS
      case tb: core.TextBox => tb.toJS
      case _ => "alert('Other')"
    }
  }

  def compiled: (NetLogoCompiler, String) = {
    Logger.info("Beginning compilation")
    val strCompilerOpt = carefullyCompile {
      val (js, newProgram, newProcedures) =
        Compiler.compileProcedures(model)
      Logger.info("No errors!")

      (this.copy(program = newProgram, procedures = newProcedures),
        js + model.widgets.map(compileWidget(_) (newProgram, newProcedures)).mkString("\n"))
    }
    Logger.info("Compilation complete")
    strCompilerOpt getOrElse ((this, ""))
  }

  def recompile(source: String): (NetLogoCompiler, String) = {
    val newCompiler = this.copy(model = model.copy(code = source))
    newCompiler.compiled
  }

  // One might be tempted to rewrite this to return a `Try`, but, incidentally, it doesn't really do
  // much for us in this case. --JAB (11/11/13)
  private def carefullyCompile[T](f: => T): Option[T] =
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
      case ex: Exception =>
        Logger.warn(s"An unknown exception has occurred: ${ex.getMessage}")
        None
    }
}

object NetLogoCompiler {

  def fromNLogoFile(contents: String): (NetLogoCompiler, String) = {
    val model = ModelReader.parseModel(contents, new DefaultParserServices(FrontEnd))
    NetLogoCompiler(model).compiled
  }

  def blank: NetLogoCompiler = NetLogoCompiler(Model())

}
