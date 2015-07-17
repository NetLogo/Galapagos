// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  play.api.{ Logger, mvc },
    mvc.{AnyContent, Action, Controller}

import
  play.api.libs.json.Json
import models.ModelsLibrary

import
  ModelsLibrary.{ allModels, prettyFilepath }

class Application extends Controller {
  def index: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.index())
  }

  def info: Action[AnyContent] = Action {
    implicit request =>
      Ok(views.html.info())
  }

  def model(modelName: String): Action[AnyContent] = {
    Logger.info("\"%s\" requested".format(modelName))
    Assets.at(path="/public/modelslib", modelName, true)
  }

  def modelList: Action[AnyContent] = Action {
    implicit request =>
      Ok(Json.stringify(Json.toJson(allModels.map(prettyFilepath))))
  }
}
