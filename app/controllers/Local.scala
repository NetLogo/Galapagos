// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.Inject

import
  play.api.{ Application => PlayApplication, libs, mvc, Play },
    libs.iteratee.Enumerator,
    mvc.{ Action, AnyContent, Controller, ResponseHeader, Result }

import
  models.Util.usingSource

class Local @Inject() (application: PlayApplication) extends Controller {
  import Local._

  private lazy val engineStr     = usingSource(_.fromURL(getClass.getResource(enginePath)))    (_.mkString)
  private lazy val agentModelStr = usingSource(_.fromURL(getClass.getResource(agentModelPath)))(_.mkString)

  implicit val mode = Play.mode(application)

  def tortoise: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.tortoise())
  }

  def standalone: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(TemplateUtil.inlineScript, TemplateUtil.inlineStyle))
  }

  def web: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(TemplateUtil.outsourceScript, TemplateUtil.outsourceStyle))
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
