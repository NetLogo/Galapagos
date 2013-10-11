package models.local

import
  scala.concurrent.{ Await, duration },
    duration._

import
  akka.{ actor, pattern, util },
    actor.{ Actor, PoisonPill, Props },
    pattern.ask,
    util.Timeout

import
  play.api.libs,
    libs.{ concurrent, json, iteratee },
      concurrent.Akka,
      iteratee.Concurrent,
        Concurrent.Channel,
      json.{ JsObject, JsValue}

import
  models.core.{ WebInstance, WebInstanceManager, WebInstanceMessages }

import
  CompilerMessages.{ Compile, Open }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class LocalInstance extends Actor with WebInstance {

  import WebInstanceMessages._

  implicit private val timeout = Timeout(1.second)

  protected val compilerManager = Akka.system.actorOf(Props[CompilerManager])

  protected var channelOpt: Option[Channel[JsValue]] = None // I wish there were an obvious and better way... --JAB (1/25/13)

  override protected def receiveExtras = {
    case Join(_) =>
      validateConnection match {
        case (true, _) =>
          val enumer = Concurrent.unicast[JsValue] {
            channel => channelOpt = Option(channel)
          }
          sender ! Connected(enumer)
        case (false, reason) =>
          sender ! CannotConnect(reason)
      }
    case Quit(_) =>
      broadcast(generateMessage(QuitKey, NetLogoUsername, RoomContext, "Tortoise is now quitting..."))
      self ! PoisonPill
  }

  override protected def broadcast(msg: JsObject): Unit =
    channelOpt foreach (_.push(msg))

  override protected def execute(agentType: String, cmd: String): Unit = {
    import CompilerMessages.Execute
    val js = Await.result(compilerManager ? Execute(agentType, cmd), 1.second).asInstanceOf[String]
    broadcast(generateMessage(JSKey, NetLogoUsername, RoomContext, js))
  }

  override protected def compile(source: String): Unit = {
    val js = Await.result(compilerManager ? Compile(source), 1.second).asInstanceOf[String]
    broadcast(generateMessage(ModelUpdateKey, NetLogoUsername, RoomContext, js))
  }

  override protected def open(nlogoContents: String): Unit = {
    val js = Await.result(compilerManager ? Open(nlogoContents), 1.second).asInstanceOf[String]
    broadcast(generateMessage(ModelUpdateKey, NetLogoUsername, RoomContext, js))
  }

  private def validateConnection = (true, "")

}

object LocalInstance extends WebInstanceManager {
  def join(): RoomType = {
    val room = Akka.system.actorOf(Props[LocalInstance])
    connectTo(room, "You")
  }
}

