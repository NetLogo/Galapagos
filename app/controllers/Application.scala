package controllers

import
  play.api.{ Logger, mvc },
    mvc.{ Action, Controller }

import
  play.api.libs.json.Json

import
  models.ModelsLibrary.{ allModels, prettyFilepath }

object Application extends Controller {

  def editor = Action {
    implicit request =>
      Ok(views.html.editor())
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
