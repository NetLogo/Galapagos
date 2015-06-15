package models

import
  java.net.URL

import
  scala.io.Codec

import
  scalaz.ValidationNel

import
  play.api.libs.json.Json

import
  org.nlogo.tortoise.CompiledModel

import
  compile.CompiledWidget,
  Util.usingSource

object ModelSaver {

  type CompilationBundleV = ValidationNel[Exception, CompilationBundle]

  def apply(compiledModel: CompiledModel, jsURLs: Seq[URL] = Seq()): CompilationBundle = {
    val CompiledModel(js, model, _, _, _) = compiledModel
    val widgets = model.widgets map CompiledWidget.compile(compiledModel)
    val depsJS  = jsURLs map slurpURL mkString("", ";\n", ";\n")
    CompilationBundle(js, depsJS, Json.toJson(widgets).toString, model.code, model.info)
  }

  private def slurpURL(url: URL): String =
    usingSource(_.fromURL(url)(Codec.ISO8859))(_.mkString)

}

case class CompilationBundle(modelJs: String, libsJs: String, widgets: String, nlogoCode: String, info: String)
