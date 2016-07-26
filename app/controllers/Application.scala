// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.{ Inject, Provider }

import
  models.ModelsLibrary,
    ModelsLibrary.{ allModels, prettyFilepath }

import
  play.api.{ Environment, libs, Logger, mvc },
    libs.json.Json,
    mvc.{AnyContent, Action, Controller}

class Application @Inject() (environment: Environment)  extends Controller {

  private implicit val mode = environment.mode

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
    Assets.versioned(path="/public/modelslib", modelName)
  }

  def modelList: Action[AnyContent] = Action {
    implicit request =>
      Ok(Json.stringify(Json.toJson(allModels.map(prettyFilepath))))
  }

  def robots: Action[AnyContent] =
    Assets.versioned(path="/public/text", "robots.txt")

  def humans: Action[AnyContent] =
    Assets.versioned(path="/public/text", "humans.txt")
}
