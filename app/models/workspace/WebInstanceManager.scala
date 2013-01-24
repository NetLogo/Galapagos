package models.workspace

import
  collection.mutable.{ Map => MutableMap },
  language.implicitConversions

import
  concurrent.{ duration, Future },
    duration._

import
  akka.{ actor, pattern, util },
    actor.Props,
    pattern.ask,
    util.Timeout

import
  org.nlogo.headless.HeadlessWorkspace

import
  play.api.{ libs, Logger },
    libs.{ concurrent => pconcurrent, json, iteratee },
      pconcurrent.Akka,
    iteratee.{ Done, Enumerator, Input, Iteratee },
    json.{ JsObject, JsString, JsValue }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

object WebInstanceManager {

  import WebInstanceMessages._

  implicit val timeout = Timeout(1.second)

  //@ This strikes me as a poor implementation... (it will change when the multi-headless system is implemented)
  val roomMap = MutableMap(0 -> Akka.system.actorOf(Props[WebInstance]))

  def join() = ???

  def join(username: String, roomNum: Int) : Future[(Iteratee[JsValue, _], Enumerator[JsValue])] = {
    val room = roomMap(roomNum)
    (room ? Join(username)).map {
      case Connected(enumerator) =>
        val iteratee = Iteratee.foreach[JsValue] {
          event => room ! Command(username, (event \ "agentType").as[String], (event \ "cmd").as[String])
        } mapDone {
          _     => room ! Quit(username)
        }
        (iteratee, enumerator)
      case CannotConnect(error) =>
        val iteratee   = Done[JsValue, Unit]((), Input.EOF)
        val enumerator = Enumerator[JsValue](JsObject(Seq("error" -> JsString(error)))).andThen(Enumerator.enumInput(Input.EOF))
        (iteratee,enumerator)
      case x =>
        Logger.warn("Unknown event: " + x.toString)
        throw new IllegalArgumentException("An unknown event has occurred on user join: " + x.toString)
    }
  }

}


