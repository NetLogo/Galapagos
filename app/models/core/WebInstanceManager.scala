package models.core

import
  concurrent.{ duration, Future },
    duration._

import
  akka.{ actor, pattern, util },
    actor.ActorRef,
    pattern.ask,
    util.Timeout

import
  play.api.{ libs, Logger },
    libs.{ json, iteratee },
      iteratee.{ Done, Enumerator, Input, Iteratee },
      json.{ JsObject, JsString, JsValue }

import play.api.libs.concurrent.Execution.Implicits.defaultContext

trait WebInstanceManager {

  implicit val timeout = Timeout(1.second)

  protected type RoomType = Future[(Iteratee[JsValue, _], Enumerator[JsValue])]

  protected def connectTo(room: ActorRef, username: String) : RoomType = {
    import WebInstanceMessages._
    (room ? Join(username)).map {
      case Connected(enumerator) =>
        val iteratee = Iteratee.foreach[JsValue] {
          event => {
            val cmd = Command(username, (event \ "agentType").as[String], (event \ "cmd").as[String])
            play.api.Logger.info(cmd.toString.lines.next)
            room ! cmd
          }
        } mapDone {
          _     => room ! Quit(username)
        }
        (iteratee, enumerator)
      case CannotConnect(error) =>
        val iteratee   = Done[JsValue, Unit]((), Input.EOF)
        val enumerator = Enumerator[JsValue](JsObject(Seq("error" -> JsString(error)))).andThen(Enumerator.enumInput(Input.EOF))
        (iteratee, enumerator)
      case x =>
        Logger.warn("Unknown event: " + x.toString)
        throw new IllegalArgumentException("An unknown event has occurred on user join: " + x.toString)
    }
  }

}

