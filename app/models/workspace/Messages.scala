package models.workspace

import
  play.api.libs.{ iteratee, json },
    iteratee.Enumerator,
    json.JsValue

object WebInstanceMessages {

  case class Join(username: String)
  case class Quit(username: String)
  case class Chatter(username: String, message: String)
  case class Command(username: String, agentType: String, cmd: String)
  case class CommandOutput(agentType: String, cmd: String)
  case class NotifyJoin(username: String)
  case class ViewUpdate(serializedUpdate: String)

  case class Connected(enumerator: Enumerator[JsValue])
  case class CannotConnect(msg: String)

}

object NetLogoControllerMessages {
  case class  Execute(agentType: String, cmd: String)
  case object Halt
  case object RequestViewUpdate
  case object RequestViewState
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
  protected val JoinKey       = "join"
  protected val ChatterKey    = "chatter"
  protected val CommandKey    = "command"
  protected val ResponseKey   = "response"
  protected val QuitKey       = "quit"
  protected val ViewUpdateKey = "update"
}
