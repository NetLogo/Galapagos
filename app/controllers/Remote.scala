package controllers

import
  play.api.{ libs, mvc },
    libs.json.JsValue,
    mvc.{ Action, Controller, WebSocket }

import
  models.workspace.WebInstance

object Remote extends Controller {

  def index = Action {
    implicit request =>
      Ok(views.html.index())
  }

  def client(usernameOpt: Option[String]) = Action {
    implicit request =>
      usernameOpt map (
        username => Ok(views.html.client(username))
      ) getOrElse (
        Redirect(routes.Remote.index()).flashing(
          "error" -> "Please choose a valid username."
        )
      )
  }

  def handleSocketConnection(username: String, room: Int = 0) = WebSocket.async[JsValue] {
    implicit request =>
      WebInstance.join(username, room)
  }

}
