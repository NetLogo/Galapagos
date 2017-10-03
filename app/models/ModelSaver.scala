// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import
  java.net.URL

import
  json.Writers.compiledWidgetWrites

import
  play.api.libs.json.Json

import
  org.nlogo.tortoise.compiler.CompiledModel

import
  scala.io.Codec

import
  scalaz.ValidationNel

import
  Util.usingSource

object ModelSaver {

  type CompilationBundleV = ValidationNel[Exception, CompilationBundle]

  def apply(compiledModel: CompiledModel, jsURLs: Seq[URL] = Seq()): CompilationBundle = {
    val CompiledModel(js, compilation, _) = compiledModel
    val model = compilation.model
    val widgets = Json.toJson(compiledModel.widgets).toString
    val depsJS  = jsURLs map slurpURL mkString("", ";\n", ";\n")
    CompilationBundle(js, depsJS, widgets, model.code, model.info)
  }

  private def slurpURL(url: URL): String =
    usingSource(_.fromURL(url)(Codec.ISO8859))(_.mkString)

}

case class CompilationBundle(modelJs: String, libsJs: String, widgets: String, nlogoCode: String, info: String)
