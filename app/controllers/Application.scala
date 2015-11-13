// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.Inject

import
  models.ModelsLibrary,
    ModelsLibrary.{ allModels, prettyFilepath }

import
  play.api.{ Application => PlayApplication, libs, Logger, Play, mvc },
    libs.json.Json,
    mvc.{AnyContent, Action, Controller}

class Application @Inject() (application: PlayApplication)  extends Controller {

  private implicit val mode = Play.mode(application)

  def index: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.mainTheme(views.html.index(), "NetLogo Web"))
  }

  def info: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.mainTheme(views.html.info(), "NetLogo Web FAQ", Option("info")))
  }

  def whatsNew: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.mainTheme(views.html.whatsNew(), "What's New in NetLogo Web", Option("updates")))
  }

  def serverError: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.mainTheme(views.html.serverError(), "NetLogo Web - Error"))
  }

  def model(modelName: String): Action[AnyContent] = {
    Logger.info("\"%s\" requested".format(modelName))
    Assets.at(path="/public/modelslib", modelName, true)
  }

  def modelList: Action[AnyContent] = Action {
    implicit request =>
      Ok(Json.stringify(Json.toJson(allModels.map(prettyFilepath))))
  }

  def robots: Action[AnyContent] =
    Assets.at(path="/public/text", "robots.txt", true)

  def humans: Action[AnyContent] =
    Assets.at(path="/public/text", "humans.txt", true)
}
