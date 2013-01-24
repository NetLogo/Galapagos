package models.workspace

import
  collection.mutable.{ Map => MutableMap },
  language.implicitConversions

import
  concurrent.{ duration, Future },
    duration._

import
  java.io.File

import
  akka.{ actor, pattern, util },
    actor.{ Actor, Props },
    pattern.ask,
    util.Timeout

import
  org.nlogo.headless.HeadlessWorkspace

import
  play.api.{ libs, Logger },
    libs.{ concurrent => pconcurrent, json, iteratee },
      pconcurrent.Akka,
      iteratee.{ Enumerator, PushEnumerator },
      json.{ JsArray, JsObject, JsString, JsValue }

import
  models.remote.{ NetLogoController, WebWorkspace }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class WebInstance extends Actor with ChatPacketProtocol with EventManagerProtocol {

  import NetLogoControllerMessages._
  import WebInstanceMessages._

  private val NameLengthLimit = 10

  private val RoomContext     = "room"
  private val ObserverContext = "observer"
  private val TurtlesContext  = "turtles"
  private val LinksContext    = "links"
  private val PatchesContext  = "patches"
  private val ChatterContext  = "chatter"
  private val NetLogoUsername = "netlogo"

  private val Contexts = List(RoomContext, ObserverContext, TurtlesContext, LinksContext, PatchesContext, ChatterContext)

  private lazy val room    = self
  private val nlController = Akka.system.actorOf(Props[NetLogoController])
  private val BizzleBot    = new models.remote.BizzleBot(room, nlController)

  private type MemberKey   = String
  private type MemberValue = PushEnumerator[JsValue]
  private type MemberTuple = (MemberKey, MemberValue)
  val members = MutableMap.empty[MemberKey, MemberValue]


  BizzleBot.start()
  Akka.system.scheduler.schedule(0.milliseconds, 30.milliseconds) {
    nlController ! RequestViewUpdate
  }

  def receive = {

    case Join(username) =>
      val channel = Enumerator.imperative[JsValue](onStart = () => room ! NotifyJoin(username))
      isValidUsername(username) match {
        case (true, _) =>
          members += username -> channel
          sender ! Connected(channel)
          nlController ! RequestViewState
        case (false, reason) =>
          sender ! CannotConnect(reason)
      }

    case NotifyJoin(username) =>
      notifyAll(generateMessage(JoinKey, RoomContext, username, "has entered the room"))

    case Chatter(username, message) =>
      if (BizzleBot.canFieldMessage(message))
        BizzleBot.offerAssistance(username, message) foreach {
          msg => notify(username, generateMessage(ChatterKey, ChatterContext, BizzleBot.BotName, msg))
        }
      else
        notifyAll(generateMessage(ChatterKey, ChatterContext, username, message))

    case Command(username, ChatterContext, message) =>
      self ! Chatter(username, message)

    case Command(username, agentType, cmd) if (Contexts.contains(agentType)) =>
      notifyAll(generateMessage(CommandKey, agentType, username, cmd))
      nlController ! Execute(agentType, cmd)

    case Command(username, agentType, cmd) =>
      Logger.warn(s"Unhandlable message from user '$username' in context '$agentType': $cmd")

    case CommandOutput(agentType, output) =>
      notifyAll(generateMessage(ResponseKey, NetLogoUsername, agentType, output))

    case Quit(username) =>
      quit(username)

    case ViewUpdate(serializedUpdate: String) =>
      notifyAll(generateMessage(ViewUpdateKey, RoomContext, NetLogoUsername, serializedUpdate))

  }

  private def quit(username: String) {
    members -= username
    notifyAll(generateMessage(QuitKey, RoomContext, username, "has left the room"))
  }

  // THIS IS WHY `Option` SHOULD SHARE A REASONABLE SUBTYPE WITH `Traversable`!
  // Also, why did my structural typing fail here...?
  implicit class Pushable[T <: Iterable[MemberTuple]](foreachable: T) {
    def pushForeach(msg: JsObject) {
      foreachable foreach { case (username, channel) =>
        // Note that push is being used for it's side effect here. The return
        // of push indicates success; ie, whether the server successfully sent
        // the message to the client.
        if (!channel.push(msg))
          quit(username)
      }
    }
  }

  private def notify(messageSets: (Iterable[String], JsObject)*) {
    messageSets foreach {
      case (memberNames, msg) => members filter { case (name, _) => memberNames.toSeq.contains(name) } pushForeach msg
    }
  }

  private def notify(memberName: String, msg: JsObject) {
    (members find (_._1 == memberName)).toIterable pushForeach msg
  }

  private def notifyBut(memberName: String, msg: JsObject) {
    members filterNot (_._1 == memberName) pushForeach msg
  }

  private def notifyAll(msg: JsObject) {
    members pushForeach msg
  }

  private def generateMessage(kind: String, context: String, user: String, text: String) =
    JsObject(
      Seq(
        KindKey    -> JsString(kind),
        ContextKey -> JsString(context),
        UserKey    -> JsString(user),
        MessageKey -> JsString(text),
        MembersKey -> JsArray(members.keySet.toList map (JsString))
      )
    )

  private def generateMultiMessage(kind: String, context: String, user: String, text: String, formats: String*) =
    formats map (f => generateMessage(kind, context, user, f.format(text)))

  protected def isValidUsername(username: String) : (Boolean, String) = {
    val reservedNames = Seq("me", "myself") ++ Contexts
    Seq(
      (reservedNames.contains(username.filter(_ != ' ')), "Username attempts to deceive others!"),
      (username.isEmpty,                                  "Username is empty"),
      (username.length >= NameLengthLimit,                "Username is too long (must be %d characters or less)".format(NameLengthLimit)),
      (members.contains(username),                        "Username already taken"),
      (username.matches(""".*[^ \w].*"""),                "Username contains invalid characters (must contain only alphanumeric characters and spaces)")
    ) collectFirst { case (cond, msg) if (cond) => (false, msg) } getOrElse (true, "Username approved")
  }

  protected def workspace(file: File) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(io.Source.fromFile(file).mkString)
    wspace
  }

}

