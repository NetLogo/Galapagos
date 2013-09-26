package controllers

import
  play.api.mvc.{ Action, Controller }

import play.api.libs.json.Json

object Application extends Controller {

  def editor = Action {
    implicit request =>
      Ok(views.html.editor())
  }

  def minimal = Action {
    implicit request =>
      Ok(views.html.examples.minimal())
  }

  def model(modelName: String) = {
    play.api.Logger.info("\"%s\" requested".format(modelName))
    controllers.Assets.at(path="/public/modelslib", modelName)
  }

  def modelList = Action {
    implicit request => {
      def recursiveListFiles(f: java.io.File): Array[java.io.File] = {
        val myFiles = f.listFiles
        myFiles ++ myFiles.filter(_.isDirectory).flatMap(recursiveListFiles)
      }
      val parentPath = "public/modelslib/"
      val nlogoFiles = Seq("Sample Models", "Code Examples", "Curricular Models").
        flatMap(dir => recursiveListFiles(new java.io.File(parentPath, dir))).
        filter(_.getName.endsWith(".nlogo"))
      Ok(Json.stringify(Json.toJson(nlogoFiles.map(_.getPath.drop(parentPath.length).dropRight(".nlogo".length)))))
    }
  }
}
