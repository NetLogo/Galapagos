package models

import akka.actor._
import akka.util.duration._

import play.api._
import play.api.libs.json._
import play.api.libs.iteratee._
import play.api.libs.concurrent._

import akka.util.Timeout
import akka.pattern.ask

import play.api.Play.current

/**
 * Created by IntelliJ IDEA.
 * User: Jason
 * Date: 7/30/12
  * Time: 12:17 PM
  */

//@
object Robot {
  def apply(chatRoom: ActorRef) {
    // Create an Iteratee that log all messages to the console.
    val loggerIteratee = Iteratee.foreach[JsValue](event => Logger("robot").info(event.toString()))
    implicit val timeout = Timeout(1 second)
    chatRoom ? (Join("Robot")) map { case Connected(robotChannel) => robotChannel |>> loggerIteratee }
    Akka.system.scheduler.schedule(30 seconds, 30 seconds, chatRoom, Talk("Robot", "I'm still alive"))
  }
}

object ChatRoom {

  implicit val timeout = Timeout(1 second)

  lazy val default = {
    val roomActor = Akka.system.actorOf(Props[ChatRoom])
    Robot(roomActor) //@ Create a bot user (just for fun)
    roomActor
  }

  def join(username: String) : Promise[(Iteratee[JsValue, _], Enumerator[JsValue])] = {
    (default ? Join(username)).asPromise.map {
      case Connected(enumerator) =>
        val iteratee = Iteratee.foreach[JsValue] { event => default ! Talk(username, (event \ "text").as[String]) }.
                                mapDone          { _     => default ! Quit(username) }
        (iteratee, enumerator)
      case CannotConnect(error) =>
        val iteratee   = Done[JsValue, Unit]((),Input.EOF)
        val enumerator = Enumerator[JsValue](JsObject(Seq("error" -> JsString(error)))).andThen(Enumerator.enumInput(Input.EOF))
        (iteratee, enumerator)
    }
  }
  
  def isUsernameTaken(name: String) : Boolean = {
    (default ? UsernameQuery(name)).asPromise.map {
      case UsernameResponse(approved) => approved
      case x                          => Logger.warn("What is this thing?  `isUsernameTaken` got this back: " + x); false
    }.await(300).get
  }

}

class ChatRoom extends Actor {

  var members = Map.empty[String, PushEnumerator[JsValue]]

  def receive = {
    case Join(username) =>
      // Create an Enumerator to write to this socket
      val channel = Enumerator.imperative[JsValue](onStart = self ! NotifyJoin(username))
      members = members + (username -> channel)
      sender ! Connected(channel)
    case UsernameQuery(username) =>
      sender ! UsernameResponse(members.contains(username))
    case NotifyJoin(username) =>
      notifyAll("join", username, "has entered the room")
    case Talk(username, text) =>
      notifyAll("talk", username, text)
    case Quit(username) =>
      members = members - username
      notifyAll("quit", username, "has left the room")
  }

  def notifyAll(kind: String, user: String, text: String) {
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

}

case class Join(username: String)
case class Quit(username: String)
case class Talk(username: String, text: String)
case class NotifyJoin(username: String)

case class UsernameQuery(username: String)
sealed case class UsernameResponse(approved: Boolean)
object UsernameResponse { def apply(approved: Boolean) = if (approved) UsernameApproved else UsernameRejected }
object UsernameRejected extends UsernameResponse(false)
object UsernameApproved extends UsernameResponse(true)

case class Connected(enumerator: Enumerator[JsValue])
case class CannotConnect(msg: String)

class DumboBox {

  //@ Could use a bit of improvement...
    def processInput(str: String) : (String, String) = {
      Json.parse(str) match { case json => ((json \ "agentType").as[String], (json \ "cmd").as[String]) }
    }

    //WebSocket.adapter[String] {
    //  request =>
    //    val x = 3
    //    play.api.libs.iteratee.Enumeratee.map[String] {
    //      input =>
    //       val y = 4
    //        "derp"
    //    }
    //}

//    WebSocket.adapter[String] {
//      request =>
//        play.api.libs.iteratee.Enumeratee.map[String] { input => val (agentType, cmd) = processInput(input); ws.execute(agentType, cmd) }
//    }

}
