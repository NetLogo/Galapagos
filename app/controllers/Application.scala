package controllers

import
  java.io.File

import
  play.api.{ Logger, mvc },
    mvc.{ Action, Controller }

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

  def climate = Action {
    implicit request =>
      Ok(views.html.examples.climate())
  }

  def wolfsheep = Action {
    implicit request =>
      Ok(views.html.examples.wolfsheep())
  }

  def model(modelName: String) = {
    Logger.info("\"%s\" requested".format(modelName))
    Assets.at(path="/public/modelslib", modelName)
  }

  def modelList = Action {
    implicit request =>
      def recursiveListFiles(f: File): Array[File] = {
        val myFiles = f.listFiles
        myFiles ++ myFiles.filter(_.isDirectory).flatMap(recursiveListFiles)
      }
      val parentPath = "public/modelslib/"
      val nlogoFiles = Seq("test/tortoise", "test/benchmarks", "Sample Models", "Code Examples", "Curricular Models").
        flatMap(dir => recursiveListFiles(new File(parentPath, dir))).
        filter(_.getName.endsWith(".nlogo"))
      Ok(Json.stringify(Json.toJson(nlogoFiles.map(_.getPath.drop(parentPath.length).stripSuffix(".nlogo")))))
  }

  def createStandaloneTortoise = Action {
    implicit request =>
      Ok(views.html.createStandalone())
  }

}
