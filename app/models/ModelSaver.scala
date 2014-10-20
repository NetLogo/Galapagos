package models

import
  java.net.URL

import
  scala.io.Codec

import
  scalaz.ValidationNel

import
  org.nlogo.{ api, compile, core => nlcore, nvm, tortoise },
    api.{ CompilerException, model, Program },
      model.ModelReader,
    compile.front.FrontEnd,
    nlcore.Widget,
    nvm.{ DefaultParserServices, FrontEndInterface },
      FrontEndInterface.ProceduresMap,
    tortoise.CompiledModel

import
  play.api.Logger

import
  local.WidgetJS

import
  Util.usingSource

object ModelSaver {

  implicit val codec = Codec.ISO8859

  type CompilationBundleV = ValidationNel[CompilerException, CompilationBundle]

  def apply(nlogo: String, jsURLs: Seq[URL]): CompilationBundleV = {
    val code = ModelReader.parseModel(nlogo, new DefaultParserServices(FrontEnd)).code
    CompiledModel.fromNlogoContents(nlogo) map {
      case CompiledModel(js, model, prog, procs, compiler) =>
        val widgetJS = model.widgets.map(compileWidget(_)(prog, procs)).mkString("\n")
        val fullJS   = s"""$widgetJS;
                          |var session = new SessionLite(document.getElementsByClassName('view-container')[0]);
                          |$js""".stripMargin
        CompilationBundle(buildJavaScript(fullJS, jsURLs), code, model.info)
    }
  }

  def apply(url: URL, jsURLs: Seq[URL]): CompilationBundleV = {
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

  // This must die --JAB (8/15/14)
  private def compileWidget(widget: Widget)(implicit program: Program, procedures: ProceduresMap): String = {
    import WidgetJS._, nlcore._
    widget match {
      case b: Button  => b.toJS
      case s: Slider  => s.toJS
      case s: Switch  => s.toJS
      case m: Monitor => m.toJS
      case v: View    => v.toJS
      case p: Plot    => p.toJS
      case t: TextBox => t.toJS
      case c: Chooser => c.toJS
      case w          => Logger.warn(s"Unconvertible widget type: ${w.getClass.getSimpleName}"); s"alert('${w.getClass.getSimpleName} widgets are not yet supported')"
    }
  }

}
