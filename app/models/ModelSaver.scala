package models

import
  java.net.URL

import
  local.NetLogoCompiler,
  Util.usingSource

import
  org.nlogo.{ api, compile, nvm },
    api.model.ModelReader,
    compile.front.FrontEnd,
    nvm.DefaultParserServices

object ModelSaver {

  def apply(nlogo: String, jsURLs: Seq[URL]): CompilationBundle = {
    val netLogoJS = NetLogoCompiler.fromNLogoFile(nlogo)._2
    val code      = ModelReader.parseModel(nlogo, new DefaultParserServices(FrontEnd)).code
    CompilationBundle(buildJavaScript(netLogoJS, jsURLs), code)
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
