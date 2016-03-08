// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.{ Inject, Provider }

import
  akka.{ stream, util },
    stream.scaladsl.Source,
    util.ByteString

import
  play.api.{ Configuration, Environment, http, libs, mvc },
    http.HttpEntity.Streamed,
    libs.iteratee.Enumerator,
    mvc.{ Action, AnyContent, Controller, ResponseHeader, Result }

import
  models.Util.usingSource

class Local @Inject() (environ: Environment, configuration: Configuration) extends Controller {
  import Local._

  private lazy val engineStr     = usingSource(_.fromURL(getClass.getResource(enginePath)))    (_.mkString)
  private lazy val agentModelStr = usingSource(_.fromURL(getClass.getResource(agentModelPath)))(_.mkString)

  implicit val environment = environ
  implicit val mode        = environment.mode

  def launch: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.tortoise())
  }

  def standalone: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(InlineTagBuilder))
  }

  def web: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(OutsourceTagBuilder))
  }

  def engine: Action[AnyContent] = Action {
    implicit request => OkJS(engineStr)
  }

  def agentModel: Action[AnyContent] = Action {
    implicit request => OkJS(agentModelStr)
  }

  private def OkJS(js: String) = {
    val bytes = js.getBytes(configuration.getString("application.defaultEncoding").getOrElse("UTF-8"))
    Result(
      header = ResponseHeader(OK, Map(CONTENT_TYPE -> "text/javascript")),
      body   = Streamed(Source.single(ByteString.fromArray(bytes)), None, None)
    )
  }

}

object Local {
  val enginePath     = "/js/tortoise-engine.js"
  val agentModelPath = "/js/tortoise/agentmodel.js"
}
