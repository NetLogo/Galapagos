package models.remote

import
  collection.{ immutable, mutable },
    immutable.{ Seq => ISeq },
    mutable.{ Map => MutableMap },
  concurrent.duration._

import
  java.io.File

import
  akka.{ actor, pattern },
    actor.{ Actor, Props },
    pattern.ask

import
  play.api.libs.{ concurrent => pconcurrent, json, iteratee },
    pconcurrent.Akka,
    iteratee.Concurrent,
      Concurrent.Channel,
    json.{ JsArray, JsObject, JsString, JsValue }

import
  org.nlogo.headless.HeadlessWorkspace

import
  models.core.{ NetLogoControllerMessages, WebInstance, WebInstanceManager, WebInstanceMessages }

import play.api.Play.current
import play.api.libs.concurrent.Execution.Implicits.defaultContext

class RemoteInstance extends Actor with WebInstance {

  import NetLogoControllerMessages._
  import WebInstanceMessages._
  import RemoteInstanceMessages._

  protected val NameLengthLimit = 10

  protected val RoomContext     = "room"
  protected val ChatterContext  = "chatter"
  override protected val extraContexts = ISeq(RoomContext, ChatterContext)

  private val nlController = Akka.system.actorOf(Props[NetLogoController])
  private val BizzleBot    = new BizzleBot(room, nlController)

  BizzleBot.start()
  Akka.system.scheduler.schedule(0.milliseconds, 30.milliseconds) {
    nlController ! RequestViewUpdate
  }

  protected type MemberKey   = String
  protected type MemberValue = Channel[JsValue]
  protected type MemberTuple = (MemberKey, MemberValue)
  val members = MutableMap.empty[MemberKey, MemberValue]

  override def receiveExtras = {

    case Join(username) =>
      isValidUsername(username) match {
        case (true, _) =>
          val enumer = Concurrent.unicast[JsValue] {
            channel =>
              members += username -> channel
              room ! NotifyJoin(username)
              nlController ! RequestViewState
          }
          sender ! Connected(enumer)
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

    case Quit(username) =>
      quit(username)

    case ViewUpdate(serializedUpdate: String) =>
      notifyAll(generateMessage(ViewUpdateKey, RoomContext, NetLogoUsername, serializedUpdate))

  }

  private def quit(username: String) {
    members -= username
    notifyAll(generateMessage(QuitKey, RoomContext, username, "has left the room"))
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

  // THIS IS WHY `Option` SHOULD SHARE A REASONABLE SUBTYPE WITH `Traversable`!
  // Also, why did my structural typing fail here...?
  implicit class Pushable[T <: Iterable[MemberTuple]](foreachable: T) {
    def pushForeach(msg: JsObject) {
      foreachable foreach { case (username, channel) => channel.push(msg) }
    }
  }


  override def broadcast(msg: JsObject)                { notifyAll(msg) }
  override def execute(agentType: String, cmd: String) = nlController ! Execute(agentType, cmd)

  override def generateMessage(kind: String, context: String, user: String, text: String) =
    super.generateMessage(kind, context, user, text) ++ JsObject(Seq(MembersKey -> JsArray(members.keySet.toList map (JsString))))

  protected def isValidUsername(username: String) : (Boolean, String) = {
    val reservedNames = Seq("me", "myself") ++ contexts
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

object RemoteInstance extends WebInstanceManager {

  //@ This strikes me as a poor implementation... (it will change when the multi-headless system is implemented)
  val roomMap = MutableMap(0 -> Akka.system.actorOf(Props[RemoteInstance]))

  def join(username: String, roomNum: Int) : RoomType = {
    val room = roomMap(roomNum)
    connectTo(room, username)
  }

}

object RemoteInstanceMessages {
  case class Chatter(username: String, message: String)
  case class NotifyJoin(username: String)
}
