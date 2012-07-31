package models

import play.api.Logger
import play.api.libs.json.{ Json, JsArray, JsObject, JsValue, JsString }
import play.api.libs.iteratee.{ Done, Enumerator, Input, Iteratee, PushEnumerator }
import play.api.libs.concurrent.{ Akka, akkaToPlay, Promise }
import play.api.Play.current

import akka.actor.{ Actor, ActorRef, Props }
import akka.pattern.ask
import akka.util.duration._
import akka.util.Timeout

import org.nlogo.headless.HeadlessWorkspace


/**
 * Created by IntelliJ IDEA.
 * User: Jason
 * Date: 7/30/12
  * Time: 12:17 PM
  */

class BizzleBot(server: ActorRef) {

  //@ Add constants for BizzleBot's name and for all of these text labels

  implicit val timeout = Timeout(1 second)

  val loggerIteratee = Iteratee.foreach[JsValue] {
    event =>
      Logger("robot").info(event.toString())
      (event \ "user").asOpt[String].flatMap (user => (event \ "message").asOpt[String] map ((user, _))).
                                     foreach { case (username, message) => offerHelp(username, message) }
  }

  server ? (Join("BizzleBot")) map { case Connected(robotChannel) => robotChannel |>> loggerIteratee }

  protected def offerHelp(username: String, message: String) {
    def preprocess(message: String) : Option[String] = {
      val trimmed = message.trim
      if (trimmed.startsWith("!")) Some(trimmed drop 1 trim) else None
    }
    preprocess(message) map {
      case "help"   =>
        "perhaps this can be of help to you:\n\n" +
        "<ul><li>Press the Tab key to change agent contexts.</li>" +
        "<li>Press the Up Arrow/Down Arrow to navigate through previously-entered commands.</li>" +
        "<li>Press Control + Shift + [any number key 1-5] to directly set yourself to use a specific agent context." +
        "<li>For information about how to use the NetLogo programming language, please consult " +
        "<a href=\"http://ccl.northwestern.edu/netlogo/docs/\">the official NetLogo user manual</a>.</li></ul>"
      case "info"   =>
        "NetLogo is a multi-agent programmable modeling environment, " +
        "authored by Uri Wilensky and developed at Northwestern University's Center for Connected Learning.  " +
        "For additional information, please visit <a href=\"http://ccl.northwestern.edu/netlogo/\">the NetLogo website</a>."
      case "whoami" =>
        "you're <b>%s</b>, obviously!".format(username)
    } foreach (response => server ! Chatter("BizzleBot", "<b>%s</b>, ".format(username) + response))
  }

}

object WebInstance {

  implicit val timeout = Timeout(1 second)

  //@ This strikes me as a poor implementation...
  var roomMap = Map(0 -> Akka.system.actorOf(Props[WebInstance]))
  new BizzleBot(roomMap(0))
  
  // You should always call `isValidUsername` before calling this
  def join(username: String, roomNum: Int) : Promise[(Iteratee[JsValue, _], Enumerator[JsValue])] = {
    val room = roomMap(roomNum)
    (room ? Join(username)).asPromise.map {
      case Connected(enumerator) =>
        val iteratee = Iteratee.foreach[JsValue] { event => room ! Command(username, (event \ "AgentType").as[String], (event \ "Cmd").as[String]) }.
                                mapDone          { _     => room ! Quit(username) }
        (iteratee, enumerator)
      case CannotConnect(error) =>
        val iteratee   = Done[JsValue, Unit]((), Input.EOF)
        val enumerator = Enumerator[JsValue](JsObject(Seq("error" -> JsString(error)))).andThen(Enumerator.enumInput(Input.EOF))
        (iteratee,enumerator)
      case x =>
        Logger.error("Unknown event: " + x.toString)
        throw new Exception("An unknown event has occurred on user join: " + x.toString) //@ Should be done beeter
    }
  }


}

class WebInstance extends Actor {

  private val NameLengthLimit = 13

  //@ Can reverse routing help here?
  private val modelsURL = "http://localhost:9001/assets/models/"
  private val modelName = "Wolf Sheep Predation"
  private lazy val ws = workspace(modelsURL + java.net.URLEncoder.encode(modelName, "UTF-8") + ".nlogo")

  var members = Map.empty[String, PushEnumerator[JsValue]]

  def receive = {
    case Join(username) =>
      val channel =  Enumerator.imperative[JsValue](onStart = self ! NotifyJoin(username))
      isValidUsername(username) match {
        case (true, _) =>
          members = members + (username -> channel)
          sender ! Connected(channel)
        case (false, reason) =>
          sender ! CannotConnect(reason)
      }
    case NotifyJoin(username) =>
      notifyAll("join", username, "has entered the room")
    case Chatter(username, message) =>
      notifyAll("chatter", username, "<i>%s</i>".format(message))
    case Command(username, "chatter", message) =>
      self ! Chatter(username, message)
    case Command(username, agentType, cmd) =>
      notifyAll("command", "<b><u>NetLogo</u></b>", "<b>%s</b>.".format(username) + ws.execute(agentType, cmd)) //@ I feel like the synchronization can improve here
    case Quit(username) =>
      members = members - username
      notifyAll("quit", username, "has left the room")
  }

  private def notifyAll(kind: String, user: String, text: String) {
    val msg = JsObject(
      Seq(
        "kind"    -> JsString(kind),
        "user"    -> JsString(user),
        "message" -> JsString(text),
        "members" -> JsArray(members.keySet.toList map (JsString))
      )
    )
    members foreach { case (_, channel) => channel.push(msg) }
  }

  // Logically speaking, chatrooms should be able to define their own restrictions on names
  protected def isValidUsername(username: String) : (Boolean, String) = {
    val reservedNames = Seq("me", "NetLogo")
    Seq(
      (reservedNames.contains(username.filter(_ != ' ')), "Username attempts to deceive others!"),
      (username.isEmpty,                                  "Username is empty"),
      (username.length >= NameLengthLimit,                "Username is too long (must be %d characters or less)".format(NameLengthLimit)),
      (members.contains(username),                        "Username already taken"),
      (username.matches(""".*[^ \w].*"""),                "Username contains invalid characters (must contain only alphanumeric characters and spaces)")
    ) collectFirst { case (cond, msg) if (cond) => (false, msg) } getOrElse (true, "Username approved")
  }

  protected def workspace(url: String) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(io.Source.fromURL(url).mkString)
    wspace
  }

}

case class Join(username: String)
case class Quit(username: String)
case class Chatter(username: String, message: String)
case class Command(username: String, agentType: String, cmd: String)
case class NotifyJoin(username: String)

case class Connected(enumerator: Enumerator[JsValue])
case class CannotConnect(msg: String)

class DumboBox {



}
