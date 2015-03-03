package models.remote

object NetLogoControllerMessages {
  case class  Execute(agentType: String, cmd: String)
  case class  Compile(source: String)
  case object Go
  case object Halt
  case class  OpenModel(nlogoContents: String)
  case object RequestViewUpdate
  case object RequestViewState
  case object ViewNeedsUpdate
  case object ResetViewState
  case object Setup
  case object Stop
  case class  ViewUpdate(serializedUpdate: String)
}
