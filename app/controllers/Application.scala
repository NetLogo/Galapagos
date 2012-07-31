package controllers

import play.api.libs.json.JsValue
import play.api.mvc.{ Action, Controller, WebSocket }

import models.WebInstance

object Application extends Controller {

  def index = Action {
    implicit request =>
      Ok(views.html.index())
  }

  def client(usernameOpt: Option[String]) = Action {
    implicit request =>
      usernameOpt map (
        username => Ok(views.html.client(username))
      ) getOrElse (
        Redirect(routes.Application.index()).flashing(
          "error" -> "Please choose a valid username."
        )
      )
  }

  def handleSocketConnection(username: String, room: Int = 0) = WebSocket.async[JsValue] {
    request =>
      WebInstance.join(username, room)
  }
  
}
