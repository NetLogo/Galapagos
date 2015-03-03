package models.remote

import
  scala.collection.{ immutable, mutable },
    immutable.{ Seq => ISeq },
    mutable.{ Map => MutableMap },
  concurrent.duration._

import
  akka.actor.{ Actor, Props }

import
  play.api.{ libs, Logger, Play },
    libs.{ concurrent => pconcurrent, json, iteratee },
      pconcurrent.{ Akka, Execution },
        Execution.Implicits.defaultContext,
      iteratee.Concurrent,
        Concurrent.Channel,
      json.{ JsArray, JsObject, JsString, JsValue },
      Play.current

class RemoteInstance
  extends Actor
  with WebContextProtocol
  with EventManagerProtocol
  with ChatPacketProtocol {

  import NetLogoControllerMessages._
  import WebInstanceMessages._
  import RemoteInstanceMessages._

  private val KillswitchKey = "application.remote.killswitch"

  protected val NameLengthLimit = 10

  protected val ChatterContext = "chatter"

  final protected def contexts = ISeq(
    ObserverContext, TurtlesContext, LinksContext, PatchesContext, RoomContext, ChatterContext)

  protected lazy val room = this.self

  private val nlController = Akka.system.actorOf(Props(new NetLogoController(self)))
  private val BizzleBot    = new BizzleBot(room, nlController)

  BizzleBot.start()
  Akka.system.scheduler.schedule(0.milliseconds, 30.milliseconds) {
    nlController ! RequestViewUpdate
  }

  protected type MemberKey   = String
  protected type MemberValue = Channel[JsValue]
  protected type MemberTuple = (MemberKey, MemberValue)

  private val members = MutableMap.empty[MemberKey, MemberValue]

  final override def receive =  {

    case Join(username) =>
      isValidUsername(username) match {
        case (true, _) =>
          Logger.info(s"$username joining")
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
      Play.application.configuration.getBoolean(KillswitchKey) foreach {
        case isKillswitching =>
          if (isKillswitching && members.filterKeys(_ != BizzleBot.BotName).isEmpty)
            nlController ! Stop
      }

    case ViewUpdate(serializedUpdate: String) =>
      if (!serializedUpdate.isEmpty)
        notifyAll(generateMessage(ViewUpdateKey, RoomContext, NetLogoUsername, serializedUpdate))

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

  private def quit(username: String): Unit = {
    members -= username
    notifyAll(generateMessage(QuitKey, RoomContext, username, "has left the room"))
  }

  private def notify(messageSets: (Iterable[String], JsObject)*): Unit =
    messageSets foreach {
      case (memberNames, msg) => members filter { case (name, _) => memberNames.toSeq.contains(name) } pushForeach msg
    }

  private def notify(memberName: String, msg: JsObject): Unit =
    (members find (_._1 == memberName)).toIterable pushForeach msg

  private def notifyBut(memberName: String, msg: JsObject): Unit =
    members filterNot (_._1 == memberName) pushForeach msg

  private def notifyAll(msg: JsObject): Unit =
    members pushForeach msg

  // THIS IS WHY `Option` SHOULD SHARE A REASONABLE SUBTYPE WITH `Traversable`!
  implicit class Pushable[T <: { def foreach[U](f: MemberTuple => U) }](foreachable: T) {
    def pushForeach(msg: JsObject): Unit =
      foreachable foreach { case (username, channel) => channel.push(msg) }
  }

  protected def generateMessage(kind: String, context: String, user: String, payloadJSON: JsValue): JsObject =
    JsObject(
      Seq(
        KindKey    -> JsString(kind),
        ContextKey -> JsString(context),
        UserKey    -> JsString(user),
        MessageKey -> payloadJSON,
        MembersKey -> JsArray(members.keySet.toList map JsString)
      )
    )

  protected def generateMessage(kind: String, context: String, user: String, payload: String): JsObject =
    generateMessage(kind, context, user, JsString(payload))

  protected def broadcast(msg: JsObject):                Unit = notifyAll(msg)
  protected def execute(agentType: String, cmd: String): Unit = nlController ! Execute(agentType, cmd)
  protected def compile(source: String):                 Unit = nlController ! Compile(source)
  protected def open(nlogoContents: String):             Unit = nlController ! OpenModel(nlogoContents)

  protected def isValidUsername(username: String): (Boolean, String) = {
    val reservedNames = Seq("me", "myself", "you") ++ contexts
    val name          = username.toLowerCase
    Seq(
      (reservedNames.contains(name.filter(_ != ' ')), "Username attempts to deceive others!"),
      (name.isEmpty,                                  "Username is empty"),
      (name.length >= NameLengthLimit,               s"Username is too long (must be $NameLengthLimit characters or less)"),
      (members.contains(name),                        "Username already taken"),
      (name.matches(""".*[^ \w].*"""),                "Username contains invalid characters (must contain only alphanumeric characters and spaces)")
    ) collectFirst { case (cond, msg) if (cond) => (false, msg) } getOrElse (true, "Username approved")
  }

}

object RemoteInstance extends WebInstanceManager {

  //@ This strikes me as a poor implementation... (it will change when the multi-headless system is implemented)
  val roomMap = MutableMap(0 -> Akka.system.actorOf(Props[RemoteInstance]))

  def join(username: String, roomNum: Int): RoomType = {
    val room = roomMap(roomNum)
    connectTo(room, username)
  }

}

object RemoteInstanceMessages {
  case class Chatter(username: String, message: String)
  case class NotifyJoin(username: String)
}
