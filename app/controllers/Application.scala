package controllers

import
  play.api.{ Logger, mvc },
    mvc.{ Action, Controller }

import
  play.api.libs.json.Json
import models.ModelsLibrary

import
  ModelsLibrary.{ allModels, prettyFilepath }

class Application extends Controller {

  def index = Action {
    implicit request =>
      Ok(views.html.index())
  }

  def model(modelName: String) = {
    Logger.info("\"%s\" requested".format(modelName))
    Assets.at(path="/public/modelslib", modelName, true)
  }

  def modelList = Action {
    implicit request =>
      Ok(Json.stringify(Json.toJson(allModels.map(prettyFilepath))))
  }

}
