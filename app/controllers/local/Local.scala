package controllers.local

import
  play.api.{ libs, mvc },
    libs.{ iteratee, json },
      iteratee.Enumerator,
      json.JsValue,
    mvc.{ Action, Controller, ResponseHeader, SimpleResult, WebSocket }

import
  models.local.LocalInstance

object Local extends Controller {

  private lazy val compatStr = io.Source.fromURL(getClass.getResource("/js/compat.js")).mkString
  private lazy val engineStr = io.Source.fromURL(getClass.getResource("/js/engine.js")).mkString

  def index = Action {
    implicit request =>
      Ok(views.html.local.client())
  }

  def handleSocketConnection() = WebSocket.async[JsValue] {
    implicit request => LocalInstance.join()
  }

  def compat = Action {
    implicit request => OkJS(compatStr)
  }

  def engine = Action {
    implicit request => OkJS(engineStr)
  }

  private def OkJS(js: String) =
    SimpleResult(
      header = ResponseHeader(200, Map(CONTENT_TYPE -> "text/javascript")),
      body   = Enumerator(js.getBytes(play.Play.application.configuration.getString("application.defaultEncoding")))
    )

}
