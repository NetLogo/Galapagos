package models

import org.nlogo.nvm.CompilerInterface
import org.nlogo.headless.HeadlessWorkspace
import org.nlogo.api.{RendererInterface, AggregateManagerInterface}
import org.nlogo.agent.World
import org.nlogo.workspace.AbstractWorkspace

/**
 * Created by IntelliJ IDEA.
 * User: Jason
 * Date: 6/22/12
 * Time: 11:42 AM
 * Description:
 *   Manages a NetLogo workspace for use in NetLogo web clients
 */

class WebWorkspace(world: World, compiler: CompilerInterface, renderer: RendererInterface,
                   aggregateManager: AggregateManagerInterface, hbmFactory: AbstractWorkspace.HubNetManagerFactory)
                   extends HeadlessWorkspace(world, compiler, renderer, aggregateManager, hbmFactory) {

  // Have to do some state juggling, due to how the `outputAreaBuffer`'s contents are managed...
  def execute(agentType: String, cmd: String) : String = {
    outputAreaBuffer.clear()
    processCommand(agentType, cmd) match { case (input, cmdStr) => generateOutput(runCommand(input, cmdStr)) }
  }

  private def processCommand(agentType: String, cmd: String) : (String, String) = {
    val in = "%s> %s\n".format(agentType, cmd)
    if (agentType != "observer")
      (in, "ask " + agentType + " [ " + cmd + "\n]")
    else
      (in, cmd)
  }

  private def runCommand(input: String, cmdStr: String) : Either[String, String] = {
    try {
      command(cmdStr)
      Right(input)
    }
    catch {
      case ex: org.nlogo.api.CompilerException => Left("ERROR: " + ex.getLocalizedMessage)
    }
  }

  private def generateOutput(resultEither: Either[String, String]) : String = {
    val outOpt = outputAreaBuffer.mkString.trim match {
      case ""  => None
      case out => Option(out)
    }
    resultEither fold ((outOpt.map(_ + "\n").getOrElse("") + _), { _ + outOpt.map("\n" + _).getOrElse("") })
  }

  override def sendOutput(oo: org.nlogo.agent.OutputObject, toOutputArea: Boolean) {
    super.sendOutput(oo, true) // This must always be `true` in order for it to show up in the web frontend
  }

}
