// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.Inject

import
  play.api.{ Configuration, Environment, mvc },
    mvc.{ Action, AnyContent, Controller }

class Local @Inject() (environ: Environment, configuration: Configuration) extends Controller with ResourceSender {

  import Local._

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
    implicit request => replyWithResource(environment)(enginePath)("text/javascript")
  }

  def agentModel: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(agentModelPath)("text/javascript")
  }

}

object Local {
  val enginePath     = "/js/tortoise-engine.js"
  val agentModelPath = "/js/tortoise/agentmodel.js"
}
