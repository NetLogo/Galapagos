// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  play.api.{ libs, mvc },
    libs.iteratee.Enumerator,
    mvc.{ Action, AnyContent, Controller, ResponseHeader, Result }

import
  models.Util.usingSource

class Local extends Controller {
  import Local._

  private lazy val engineStr     = usingSource(_.fromURL(getClass.getResource(enginePath)))    (_.mkString)
  private lazy val agentModelStr = usingSource(_.fromURL(getClass.getResource(agentModelPath)))(_.mkString)

  def createStandaloneTortoise: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.createStandalone())
  }

  def tortoise: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.tortoise())
  }

  def engine: Action[AnyContent] = Action {
    implicit request => OkJS(engineStr)
  }

  def agentModel: Action[AnyContent] = Action {
    implicit request => OkJS(agentModelStr)
  }

  private def OkJS(js: String) =
    Result(
      header = ResponseHeader(OK, Map(CONTENT_TYPE -> "text/javascript")),
      body   = Enumerator(js.getBytes(play.Play.application.configuration.getString("application.defaultEncoding")))
    )

}

object Local {
  val enginePath     = "/js/tortoise-engine.js"
  val agentModelPath = "/js/tortoise/agentmodel.js"
}
