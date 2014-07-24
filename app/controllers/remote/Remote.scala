package controllers.remote

import
  play.api.{ libs, mvc },
    libs.json.JsValue,
    mvc.{ Action, Controller, WebSocket }

import
  models.remote.RemoteInstance

object Remote extends Controller {

  def index = Action {
    implicit request =>
      Ok(views.html.remote.index())
  }

  def client(usernameOpt: Option[String]) = Action {
    implicit request =>
      usernameOpt map (
        username => Ok(views.html.remote.client(username))
      ) getOrElse (
        Redirect(routes.Remote.index()).flashing(
          "error" -> "Please choose a valid username."
        )
      )
  }

  def embedded = Action {
    implicit request =>
      Ok(views.html.remote.embedded())
  }

  def handleSocketConnection(username: String, room: Int = 0) = WebSocket.tryAccept[JsValue] {
    implicit request => RemoteInstance.join(username, room)
  }

}
