package controllers

import
  play.api.{ libs, mvc },
    libs.json.JsValue,
    mvc.{ Action, Controller, WebSocket }

import models.workspace.WebInstanceManager

object Local extends Controller {

  def index = Action {
    implicit request =>
      Ok(views.html.local.client())
  }

  def handleSocketConnection() = WebSocket.async[JsValue] {
    implicit request =>
      WebInstanceManager.join()
  }

}
