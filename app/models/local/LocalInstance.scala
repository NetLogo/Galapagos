package models.local

import
  akka.actor.{ Actor, PoisonPill, Props }

import
  play.api.libs,
    libs.{ concurrent, json, iteratee },
      concurrent.Akka,
      iteratee.Enumerator,
      json.{ JsObject, JsValue }

import
  models.core.{ WebInstance, WebInstanceManager, WebInstanceMessages }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class LocalInstance extends Actor with WebInstance {

  import WebInstanceMessages._

  protected val channel = Enumerator.imperative[JsValue]()

  override protected def receiveExtras = {

    case Join(_) =>
      validateConnection match {
        case (true, _) =>
          sender ! Connected(channel)
        case (false, reason) =>
          sender ! CannotConnect(reason)
      }

    case Quit(_) =>
      broadcast(generateMessage(QuitKey, NetLogoUsername, ObserverContext, "Tortoise is now quitting..."))
      self ! PoisonPill

  }

  override protected def broadcast(msg: JsObject) { channel.push(msg) }
  override protected def execute(agentType: String, cmd: String) { ??? } //@ Fill in

  private def validateConnection = (true, "")

}

object LocalInstance extends WebInstanceManager {
  def join() : RoomType = {
    val room = Akka.system.actorOf(Props[LocalInstance])
    connectTo(room, "You")
  }
}

