package models.remote.workspace

import
  org.nlogo.{ headless, api },
    headless.HeadlessWorkspace,
    api.{ CompilerException, LogoException }

trait Executor extends HeadlessWorkspace {

  // Have to do some state juggling, due to how the `outputAreaBuffer`'s contents are managed...
  def execute(agentType: String, cmd: String): String = {
    outputAreaBuffer.clear()
    generateOutput(runCommand(processCommand(agentType, cmd)))
  }

  private def processCommand(agentType: String, cmd: String): String =
    if (agentType != "observer")
      "ask " + agentType + " [ " + cmd + "\n]"
    else
      cmd

  // Returns an error message (if any)
  private def runCommand(cmdStr: String): Option[String] = {
    try {
      command(cmdStr)
      None
    }
    catch {
      case ex: CompilerException =>
        Some("ERROR: " + ex.getLocalizedMessage)
      case ex: LogoException =>
        Some("RUNTIME ERROR: " + ex.getLocalizedMessage)
    }
  }

  private def generateOutput(errorMsg: Option[String]): String = {
    val outOpt = Some(outputAreaBuffer.mkString.trim) filter (_.nonEmpty)
    errorMsg map ((outOpt map (_ + "\n") getOrElse "") + _) getOrElse (outOpt getOrElse "")
  }

  override def sendOutput(oo: org.nlogo.agent.OutputObject, toOutputArea: Boolean) {
    // toOutputArea must always be true in order for it to show up in the web frontend
    super.sendOutput(oo, true)
  }
}
