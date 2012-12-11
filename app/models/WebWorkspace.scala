package models

import org.nlogo.api
import org.nlogo.nvm.CompilerInterface
import org.nlogo.headless.HeadlessWorkspace
import org.nlogo.agent.World
import org.nlogo.workspace.AbstractWorkspace

/**
  * Manages a NetLogo workspace for use in NetLogo web clients
  */

class WebWorkspace(world: World, compiler: CompilerInterface, renderer: api.RendererInterface,
                   aggregateManager: api.AggregateManagerInterface, hbmFactory: AbstractWorkspace.HubNetManagerFactory)
                   extends HeadlessWorkspace(world, compiler, renderer, aggregateManager, hbmFactory) {

  // Have to do some state juggling, due to how the `outputAreaBuffer`'s contents are managed...
  def execute(agentType: String, cmd: String) : String = {
    outputAreaBuffer.clear()
    generateOutput(runCommand(processCommand(agentType, cmd)))
  }

  private def processCommand(agentType: String, cmd: String) : String =
    if (agentType != "observer") "ask " + agentType + " [ " + cmd + "\n]" else cmd

  // Returns an error message (if any)
  private def runCommand(cmdStr: String) : Option[String] = {
    try {
      command(cmdStr)
      None
    }
    catch {
      case ex: api.CompilerException =>
        Option("ERROR: " + ex.getLocalizedMessage)
      case ex: api.LogoException =>
        Option("RUNTIME ERROR: " + ex.getLocalizedMessage)
    }
  }

  private def generateOutput(errorMsg: Option[String]) : String = {
    val outOpt = outputAreaBuffer.mkString.trim match {
      case ""  => None
      case out => Option(out)
    }
    errorMsg map ((outOpt map (_ + "\n") getOrElse "") + _) getOrElse (outOpt getOrElse "")
  }

  override def sendOutput(oo: org.nlogo.agent.OutputObject, toOutputArea: Boolean) {
    super.sendOutput(oo, true) // This must always be `true` in order for it to show up in the web frontend
  }

}
