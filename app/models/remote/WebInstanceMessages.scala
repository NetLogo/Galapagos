package models.remote

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
