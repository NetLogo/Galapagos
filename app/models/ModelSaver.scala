package models

import
  java.net.URL

import
  local.NetLogoCompiler,
  Util.usingSource

object ModelSaver {

  def apply(source: String, dimensions: (Int, Int, Int, Int), urls: Seq[URL]): String = {
    val netLogoJS = NetLogoCompiler.generateJS(source, dimensions)
    buildJavaScript(netLogoJS, urls)
  }

  def apply(url: URL, jsURLs: Seq[URL]): String = {
    val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
    val netLogoJS     = NetLogoCompiler.fromNLogoFile(nlogoContents)._2
    buildJavaScript(netLogoJS, jsURLs)
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
