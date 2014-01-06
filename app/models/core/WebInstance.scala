package models.core

import
  collection.immutable.{ Seq => ISeq }

import
  akka.actor.Actor

import
  play.api.{ libs, Logger },
    libs.json.{ JsObject, JsString }

trait WebInstance extends ChatPacketProtocol with EventManagerProtocol {

  self: Actor =>

  import WebInstanceMessages._

  protected val ObserverContext = "observer"
  protected val TurtlesContext  = "turtles"
  protected val LinksContext    = "links"
  protected val PatchesContext  = "patches"
  protected val RoomContext     = "room"
  protected val NetLogoUsername = "netlogo"

  final protected def baseContexts  = ISeq(ObserverContext, TurtlesContext, LinksContext, PatchesContext)
  /*~*/ protected def extraContexts = ISeq[String]()
  final protected def contexts      = baseContexts ++ extraContexts

  protected lazy val room = this.self

  protected def receiveBase: this.Receive = {
    case Command(username, agentType, cmd) if (contexts.contains(agentType)) =>
      broadcast(generateMessage(CommandKey, agentType, username, cmd))
      execute(agentType, cmd)
    case Command(username, "compile", cmd) =>
      Logger.info("Compiling")
      compile(cmd)
    case Command(username, "open", cmd) =>
      Logger.info("Opening")
      open(cmd)
    case Command(username, agentType, cmd) =>
      Logger.warn(s"Unhandlable message from user '$username' in context '$agentType': $cmd")
    case CommandOutput(agentType, output) =>
      broadcast(generateMessage(ResponseKey, NetLogoUsername, agentType, output))
  }

  protected def receiveExtras: this.Receive

  final override def receive = receiveExtras orElse receiveBase

  protected def generateMessage(kind: String, context: String, user: String, text: String) =
    JsObject(
      Seq(
        KindKey    -> JsString(kind),
        ContextKey -> JsString(context),
        UserKey    -> JsString(user),
        MessageKey -> JsString(text)
      )
    )

  protected def broadcast(msg: JsObject)
  protected def execute(agentType: String, cmd: String)
  protected def compile(source: String)
  protected def open(nlogoContents: String)

  protected def generateMultiMessage(kind: String, context: String, user: String, text: String, formats: String*) =
    formats map (f => generateMessage(kind, context, user, f.format(text)))

}
