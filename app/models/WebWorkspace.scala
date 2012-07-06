package models

import org.nlogo.nvm.CompilerInterface
import org.nlogo.headless.HeadlessWorkspace
import org.nlogo.api.{RendererInterface, AggregateManagerInterface}
import org.nlogo.agent.World
import org.nlogo.workspace.AbstractWorkspace
import play.api.libs.json.{JsValue, Json}

/**
 * Created by IntelliJ IDEA.
 * User: Jason
 * Date: 6/22/12
 * Time: 11:42 AM
 */

class WebWorkspace(world: World, compiler: CompilerInterface, renderer: RendererInterface,
                   aggregateManager: AggregateManagerInterface, hbmFactory: AbstractWorkspace.HubNetManagerFactory)
                   extends HeadlessWorkspace(world, compiler, renderer, aggregateManager, hbmFactory) {

  private var errorOpt: Option[String] = None // Ehh... could be worse

  def processInput(commandStr: String) {
    // Tries to parse `commandStr` as a JS object with two properties: `agentType` and `cmd`
    // (Which debatably sucks, since the JS object's property names could theoretically
    //  change at any time, effectively breaking this code.)
    // If it fails to parse as JSON, `commandStr` is treated as a raw NetLogo command string
    val (input, cmdStr) = {
      try {

        def morph(js: JsValue) = js.asOpt[String].get

        val js = Json.parse(commandStr)
        val (agentType, cmd) = (morph(js \ "agentType"), morph(js \ "cmd"))
        val in = "%s> %s\n".format(agentType, cmd)

        if (agentType != "observer")
          (in, "ask " + agentType + " [ " + cmd + "\n]")
        else
          (in, cmd)

      }
      catch {
        case ex: com.codahale.jerkson.ParsingException => ("", commandStr)
      }
    }

    {
      try {
        command(cmdStr)
        Right(input)
      }
      catch {
        case ex: org.nlogo.api.CompilerException => Left("ERROR: " + ex.getLocalizedMessage)
      }
    } fold((x => errorOpt = Option(x)), { x => outputAreaBuffer.append(x); errorOpt = None })

  }

  override def sendOutput(oo: org.nlogo.agent.OutputObject, toOutputArea: Boolean) {
    super.sendOutput(oo, true) // This must always be `true` in order for it to show up in the web frontend
  }

  def getOutput: String = {
    outputAreaBuffer.mkString.trim + (errorOpt map ("\n" + _) getOrElse(""))
  }

}
