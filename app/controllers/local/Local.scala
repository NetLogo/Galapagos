package controllers.local

import
  play.api.{ libs, mvc },
    libs.{ iteratee, json },
      iteratee.Enumerator,
      json.JsValue,
    mvc.{ Action, Controller, ResponseHeader, Result, WebSocket }

import
  models.{ local, core },
    local.LocalInstance,
    core.Util.usingSource

object Local extends Controller {

  private lazy val engineStr = usingSource(_.fromURL(getClass.getResource("/js/tortoise-engine.js")))(_.mkString)

  def index = Action {
    implicit request =>
      Ok(views.html.local.client())
  }

  def createStandaloneTortoise = Action {
    implicit request =>
      Ok(views.html.local.createStandalone())
  }

  def tortoise = Action {
    implicit request =>
      Ok(views.html.local.tortoise())
  }

  def handleSocketConnection() = WebSocket.tryAccept[JsValue] {
    implicit request => LocalInstance.join()
  }

  def engine = Action {
    implicit request => OkJS(engineStr)
  }

  private def OkJS(js: String) =
    Result(
      header = ResponseHeader(200, Map(CONTENT_TYPE -> "text/javascript")),
      body   = Enumerator(js.getBytes(play.Play.application.configuration.getString("application.defaultEncoding")))
    )

}
