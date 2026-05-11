// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import javax.inject.Inject

import play.api.{ Configuration, Environment, Mode }
import play.api.libs.json.{ Format, Json }
import play.api.mvc.{ AbstractController, Action, AnyContent, ControllerComponents, Request }

case class VersionEntry(version: String, commit: String, link: Option[String])

object VersionEntry {
  implicit val format: Format[VersionEntry] = Json.format[VersionEntry]
}

class Local @Inject() ( components: ControllerComponents
                      , configuration: Configuration
                      , environ: Environment
                      )  extends AbstractController(components) with ResourceSender {

  import Local._

  implicit val environment: Environment = environ
  implicit val mode:        Mode        = environment.mode

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
      Ok(views.html.simulation(InlineTagBuilder, isStandalone = true, nlwCommit = GitVersion.commitVersion))
  }

  def web: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.simulation(OutsourceTagBuilder, nlwCommit = GitVersion.commitVersion))
  }

  def jumpto: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.jump())
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

  def versionList: Action[AnyContent] = Action {
    implicit request => {
      val currentCommit = GitVersion.commitVersion
      val versionNumber = GitVersion.releaseVersion

      val versionEntries = GitVersion.allReleaseTags.map { tag =>
        val ver        = tag.stripPrefix("v")
        val commit     = GitVersion.commitForRef(tag)
        val fileExists = environment.getFile(s"public/versions/$ver.html").exists()
        val link       = if (fileExists) Some(s"versions/$ver") else None
        VersionEntry(ver, commit, link)
      }

      Ok(Json.obj(
        "current"  -> versionNumber,
        "commit"   -> currentCommit,
        "releases" -> Json.toJson(versionEntries)
      ))
    }
  }

  def versionedStandalone(version: String): Action[AnyContent] = Action {
    implicit request =>
      if (version.matches("[a-zA-Z0-9._-]+"))
        replyWithResource(environment)(s"public/versions/$version.html")("text/html; charset=utf-8")
      else
        BadRequest
  }

  def engine: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(enginePath)("text/javascript")
  }

  def engineMap: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(engineMapPath)("application/octet-stream")
  }

  def engineSource: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(engineSourcePath)("text/javascript")
  }

  def agentModel: Action[AnyContent] = Action {
    implicit request => replyWithResource(environment)(agentModelPath)("text/javascript")
  }

}

object Local {
  val enginePath       = "/tortoise-engine.min.js"
  val engineMapPath    = "/tortoise-engine.min.js.map"
  val engineSourcePath = "/tortoise-engine.js"
  val agentModelPath   = "/js/tortoise/agentmodel.js"
}
