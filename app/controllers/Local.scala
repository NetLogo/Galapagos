package controllers

import
  play.api.{ libs, mvc },
    libs.iteratee.Enumerator,
    mvc.{ Action, Controller, ResponseHeader, Result }

import
  models.Util.usingSource

object Local extends Controller {

  private lazy val engineStr     = usingSource(_.fromURL(getClass.getResource("/js/tortoise-engine.js")))    (_.mkString)
  private lazy val agentModelStr = usingSource(_.fromURL(getClass.getResource("/js/tortoise/agentmodel.js")))(_.mkString)

  def createStandaloneTortoise = Action {
    implicit request =>
      Ok(views.html.createStandalone())
  }

  def tortoise = Action {
    implicit request =>
      Ok(views.html.tortoise())
  }

  def engine = Action {
    implicit request => OkJS(engineStr)
  }

  def agentModel = Action {
    implicit request => OkJS(agentModelStr)
  }

  private def OkJS(js: String) =
    Result(
      header = ResponseHeader(200, Map(CONTENT_TYPE -> "text/javascript")),
      body   = Enumerator(js.getBytes(play.Play.application.configuration.getString("application.defaultEncoding")))
    )

}
