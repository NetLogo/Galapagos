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

  def iframeTest: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.iframeTest())
  }

  def standalone: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(InlineTagBuilder, isStandalone = true))
  }

  def web: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(OutsourceTagBuilder))
  }

  def hnwAuthoring: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwAuthoring(OutsourceTagBuilder))
  }

  def hnwAuthoringCode: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwAuthoringCode(OutsourceTagBuilder))
  }

  def hnwAuthoringInner: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwAuthoringInner(OutsourceTagBuilder))
  }

  def hnwHost: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.hnwHost(OutsourceTagBuilder))
  }

   def commandCenterPane: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.commandCenterPane(OutsourceTagBuilder))
  }

  def codePane: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.codePane(OutsourceTagBuilder))
  }

  def infoPane: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.infoPane(OutsourceTagBuilder))
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
