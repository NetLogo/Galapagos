package models.remote

import
  concurrent.{ duration, Future },
    duration._

import
  akka.{ actor, pattern, util },
    actor.ActorRef,
    pattern.ask,
    util.Timeout

import
  play.api.{ libs, Logger, mvc },
    libs.{ json, iteratee },
      iteratee.{ Done, Enumerator, Input, Iteratee },
      json.{ JsObject, JsString, JsValue },
    mvc.Result

import play.api.libs.concurrent.Execution.Implicits.defaultContext

trait WebInstanceManager {

  import models.remote.WebInstanceMessages._

  implicit val timeout = Timeout(1.second)

  protected type RoomType = Future[Either[Result, (Iteratee[JsValue, _], Enumerator[JsValue])]]

  protected def connectTo(room: ActorRef, username: String): RoomType =
    room ? Join(username) map {
      case Connected(enumerator) =>
        val iteratee = Iteratee.foreach[JsValue] {
          event => {
            val cmd = Command(username, (event \ "agentType").as[String], (event \ "cmd").as[String])
            Logger.info(cmd.toString.lines.next())
            room ! cmd
          }
        } map {
          _ => room ! Quit(username)
        }
        Right((iteratee, enumerator))
      case CannotConnect(error) =>
        val iteratee   = Done[JsValue, Unit]((), Input.EOF)
        val enumerator = Enumerator[JsValue](JsObject(Seq("error" -> JsString(error)))).andThen(Enumerator.enumInput(Input.EOF))
        Right((iteratee, enumerator))
      case x =>
        Logger.warn(s"Unknown event: $x")
        throw new IllegalArgumentException(s"An unknown event has occurred on user join: $x")
    }

}

