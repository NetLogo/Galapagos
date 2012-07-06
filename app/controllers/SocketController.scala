package controllers

import socketio.SocketIOController
import play.api.libs.concurrent.Akka
import akka.actor.Props
import models.SocketActor

/**
 * Created by IntelliJ IDEA.
 * User: Jason
 * Date: 6/22/12
 * Time: 11:51 AM
 */

object SocketController extends SocketIOController {
  lazy val socketIOActor = Akka.system.actorOf(Props[SocketActor])
}
