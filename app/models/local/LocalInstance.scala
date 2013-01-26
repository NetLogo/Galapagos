package models.local

import
  akka.actor.{ Actor, PoisonPill, Props }

import
  play.api.libs,
    libs.{ concurrent, json, iteratee },
      concurrent.Akka,
      iteratee.Concurrent,
        Concurrent.Channel,
      json.{ JsObject, JsValue}

import
  models.core.{ WebInstance, WebInstanceManager, WebInstanceMessages }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class LocalInstance extends Actor with WebInstance {

  import WebInstanceMessages._

  protected var channelOpt: Option[Channel[JsValue]] = None // I wish there were an obvious and better way... --JAB (1/25/13)

  override protected def receiveExtras = {

    case Join(_) =>
      validateConnection match {
        case (true, _) =>
          val enumer = Concurrent.unicast[JsValue] {
            channel =>
              channelOpt = Option(channel)
              broadcast(generateModelStateMessage)
          }
          sender ! Connected(enumer)
        case (false, reason) =>
          sender ! CannotConnect(reason)
      }

    case Quit(_) =>
      broadcast(generateMessage(QuitKey, NetLogoUsername, RoomContext, "Tortoise is now quitting..."))
      self ! PoisonPill

  }

  override protected def broadcast(msg: JsObject) {
    channelOpt foreach (_.push(msg))
  }

  override protected def execute(agentType: String, cmd: String) {
    broadcast(generateMessage(JSKey, NetLogoUsername, RoomContext, NetLogoCompiler(agentType, cmd)))
  }

  private def validateConnection = (true, "")
  private def generateModelStateMessage = generateMessage(ModelUpdateKey, RoomContext, NetLogoUsername, NetLogoCompiler.generateModelState)

}

object LocalInstance extends WebInstanceManager {
  def join() : RoomType = {
    val room = Akka.system.actorOf(Props[LocalInstance])
    connectTo(room, "You")
  }
}

