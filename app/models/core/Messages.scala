package models.core

import
  play.api.libs.{ iteratee, json },
    iteratee.Enumerator,
    json.JsValue

object WebInstanceMessages {

  case class Join(username: String)
  case class Quit(username: String)

  case class Command(username: String, agentType: String, cmd: String)
  case class CommandOutput(agentType: String, cmd: String)

  case class CannotConnect(msg: String)
  case class Connected(enumerator: Enumerator[JsValue])

}

object NetLogoControllerMessages {
  case class  Execute(agentType: String, cmd: String)
  case object Go
  case object Halt
  case class  NewModel(modelName: String)
  case object RequestViewUpdate
  case object RequestViewState
  case object Setup
  case object Stop
  case class  ViewUpdate(serializedUpdate: String)
}

trait ChatPacketProtocol {
  protected val KindKey     = "kind"
  protected val ContextKey  = "context"
  protected val UserKey     = "user"
  protected val MessageKey  = "message"
  protected val MembersKey  = "members"
  protected val ErrorKey    = "error"
}

trait EventManagerProtocol {
  protected val JoinKey        = "join"
  protected val ChatterKey     = "chatter"
  protected val CommandKey     = "command"
  protected val ResponseKey    = "response"
  protected val QuitKey        = "quit"
  protected val ViewUpdateKey  = "update"
  protected val ModelUpdateKey = "model_update"
  protected val JSKey          = "js"
}
