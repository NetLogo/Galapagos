package controllers

import
  play.api.mvc.{ Action, Controller }

import java.net.URLDecoder

object Application extends Controller {

  def editor = Action {
    implicit request =>
      Ok(views.html.editor())
  }

  def minimal = Action {
    implicit request =>
      Ok(views.html.examples.minimal())
  }

  def model(modelName: String) =
    controllers.Assets.at(path="/public/modelslib", URLDecoder.decode(modelName, "UTF-8"))
}
