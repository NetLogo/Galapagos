package models

import socketio.SocketIOActor
import play.api.libs.json.JsValue
import play.api.Logger

/**
 * Created by IntelliJ IDEA.
 * User: Jason
 * Date: 6/22/12
 * Time: 11:48 AM
 */

class SocketActor extends SocketIOActor {
  def processMessage : PartialFunction[(String, (String, String, Any)), Unit] = {
    case x @ ("message", (sessionId: String, namespace: String, msg: String)) =>
      Logger.info("Got message: " + x) // Regular message
    case y @ ("someEvt", (sessionId: String, namespace: String, eventData: JsValue)) =>
      Logger.info("Got event: " + y) // Event handler
    case other => Logger.debug("Failed to process socket message: " + other)
  }
}
