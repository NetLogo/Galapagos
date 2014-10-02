package models.local

import
  akka.actor.{ Actor, PoisonPill, Props }

import
  scalaz.{ NonEmptyList, Scalaz, Validation, ValidationNel },
    Scalaz.ToValidationOps

import
  org.nlogo.{ api, core, tortoise },
    api.CompilerException,
    core.AgentKind,
      AgentKind._,
    tortoise.CompiledModel

import
  play.api.{ libs, Logger },
    libs.{ concurrent, json, iteratee },
      concurrent.Akka,
      iteratee.Concurrent,
        Concurrent.Channel,
      json.{ JsObject, Json, JsValue }

import
  models.core.{ WebInstance, WebInstanceManager, WebInstanceMessages }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class LocalInstance extends Actor with WebInstance {

  import WebInstanceMessages._

  protected var channelOpt: Option[Channel[JsValue]] = None // I wish there were an obvious and better way... --JAB (1/25/13)
  protected var compiledModel = CompiledModel.fromCode("").getOrElse(throw new Exception("Failed to start up NetLogo compiler"))

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

  override protected def execute(agentKindStr: String, cmd: String): Unit = {
    kindStringToKind(agentKindStr) fold (
      Logger.warn(_: String),
      agentKind => {
        compiledModel.compileCommand(cmd, agentKind) fold (
          nel => Logger.warn(s"Command failed to compile for this reason: ${nel.list.mkString("\n")}"),
          js  => broadcast(generateMessage(JSKey, NetLogoUsername, RoomContext, js))
        )
      }
    )
  }

  override protected def compile(source: String): Unit = {
    handleCompiledModelV(CompiledModel.fromCompiledModel(source, compiledModel))
  }

  override protected def open(nlogoContents: String): Unit = {
    handleCompiledModelV(CompiledModel.fromNlogoContents(nlogoContents))
  }

  private def validateConnection = (true, "")

  private val logErrors = (nel: NonEmptyList[CompilerException]) => Logger.warn(nel.list.mkString("\n"))

  private val handleCompiledModelV = (compiledModelV: ValidationNel[CompilerException, CompiledModel]) =>
    compiledModelV fold (
      logErrors,
      model => {
        compiledModel = model
        val jsObj     = Json.obj("code" -> model.compiledCode, "info" -> model.model.info)
        broadcast(generateMessage(ModelUpdateKey, NetLogoUsername, RoomContext, jsObj))
      }
    )

  private val kindStringToKind: PartialFunction[String, Validation[String, AgentKind]] = {
    case "turtles"  => Turtle.  success
    case "patches"  => Patch.   success
    case "links"    => Link.    success
    case "observer" => Observer.success
    case x          => s"Unknown agent type: $x".failure
  }

}

object LocalInstance extends WebInstanceManager {
  def join(): RoomType = {
    val room = Akka.system.actorOf(Props[LocalInstance])
    connectTo(room, "You")
  }
}

