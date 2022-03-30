// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.Inject

import
  play.api.{ Configuration, Environment, mvc },
    mvc.{ AbstractController, Action, AnyContent, ControllerComponents, Request }

class Local @Inject() ( components: ControllerComponents
                      , configuration: Configuration
                      , environ: Environment
                      )  extends AbstractController(components) with ResourceSender {

  import Local._

  implicit val environment = environ
  implicit val mode        = environment.mode

  def launch: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.tortoise())
  }

  def ntangoBuild: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.netTangoBuilder(OutsourceTagBuilder))
  }

  def ntangoPlay: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.netTangoPlayer(InlineTagBuilder))
  }

  def standalone: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(InlineTagBuilder))
  }

  def web: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(OutsourceTagBuilder))
  }

  def hnwConfig: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwConfig())
  }

  def hnwConfigCode: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwConfigCode(OutsourceTagBuilder))
  }

  def hnwConfigInner: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwConfigInner(OutsourceTagBuilder))
  }

  def hnwHost: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwHost(OutsourceTagBuilder))
  }

   def commandCenter: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.commandCenter(OutsourceTagBuilder))
  }

  def codeModal: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.codeModal(OutsourceTagBuilder))
  }

  def infoModal: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.infoModal(OutsourceTagBuilder))
  }

  def hnwJoin: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwJoin(OutsourceTagBuilder))
  }

  def engine: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(enginePath)("text/javascript")
  }

  def agentModel: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(agentModelPath)("text/javascript")
  }

}

object Local {
  val enginePath     = "/tortoise-engine.js"
  val agentModelPath = "/js/tortoise/agentmodel.js"
}
