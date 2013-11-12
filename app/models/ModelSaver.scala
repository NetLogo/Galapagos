package models

import
  java.net.URL

import
  local.NetLogoCompiler,
  Util.usingSource

import
  org.nlogo.api.{ ModelReader, ModelSection }

object ModelSaver {

  def apply(source: String, dimensions: (Int, Int, Int, Int), urls: Seq[URL]): CompilationBundle = {
    val netLogoJS = NetLogoCompiler.fromCodeAndDims(source, dimensions)._2
    CompilationBundle(buildJavaScript(netLogoJS, urls), source)
  }

  def apply(nlogo: String, jsURLs: Seq[URL]): CompilationBundle = {
    val netLogoJS = NetLogoCompiler.fromNLogoFile(nlogo)._2
    val colorized = ModelReader.parseModel(nlogo)(ModelSection.Code).mkString("\n")
    CompilationBundle(buildJavaScript(netLogoJS, jsURLs), colorized)
  }

  def apply(url: URL, jsURLs: Seq[URL]): CompilationBundle = {
    val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
    apply(nlogoContents, jsURLs)
  }

  private def buildJavaScript(netLogoJS: String, jsURLs: Seq[URL]): String =
    jsURLs map {
      url => usingSource(_.fromURL(url))(_.mkString)
    } mkString (
      "", ";\n", ";\n"
    ) concat {
      netLogoJS
    }

}
