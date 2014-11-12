package models

import
  java.net.URL

import
  scala.io.Codec

import
  scalaz.{ Scalaz, Validation, ValidationNel },
    Scalaz.{ ToApplyOpsUnapply, ToValidationOps },
    Validation.FlatMap.ValidationFlatMapRequested

import
  org.nlogo.{ api, compile, core => nlcore, nvm, tortoise },
    api.{ model, Program },
      model.ModelReader,
    compile.front.FrontEnd,
    nlcore.Widget,
    nvm.{ DefaultParserServices, FrontEndInterface },
      FrontEndInterface.ProceduresMap,
    tortoise.CompiledModel

import
  local.WidgetJS

import
  Util.usingSource

object ModelSaver {

  implicit val codec = Codec.ISO8859

  type CompilationBundleV = ValidationNel[Exception, CompilationBundle]

  def apply(nlogo: String, jsURLs: Seq[URL]): CompilationBundleV = {
    val code = ModelReader.parseModel(nlogo, new DefaultParserServices(FrontEnd)).code
    CompiledModel.fromNlogoContents(nlogo) flatMap {
      case CompiledModel(js, model, prog, procs, compiler) =>
        val compiledWidgets = model.widgets.map(compileWidget(_)(prog, procs))
        compiledWidgets.foldLeft("".successNel[Exception]) {
          case (x, y) => (x |@| y)(_ + "\n" + _)
        }.map(
          widgetJS =>
            s"""$widgetJS;
                |var session = new SessionLite(document.getElementsByClassName('view-container')[0]);
                |$js""".stripMargin
        ).map(
          fullJS => CompilationBundle(buildJavaScript(fullJS, jsURLs), code, model.info)
        )
    }
  }

  def apply(url: URL, jsURLs: Seq[URL]): CompilationBundleV = {
    val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
    apply(nlogoContents, jsURLs)
  }

  def validateWidgets(model: CompiledModel): ValidationNel[Exception, Unit] = {
    import scalaz.Scalaz._
    model.model.widgets.map(w => compileWidget(w)(model.program, model.procedures)).filter(_.isFailure).sequenceU.map(_ => ())
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
  private def compileWidget(widget: Widget)(implicit program: Program, procedures: ProceduresMap): ValidationNel[Exception, String] = {
    import WidgetJS._, nlcore._
    widget match {
      case b: Button  => b.toJS.successNel
      case s: Slider  => s.toJS.successNel
      case s: Switch  => s.toJS.successNel
      case m: Monitor => m.toJS.successNel
      case v: View    => v.toJS.successNel
      case p: Plot    => p.toJS.successNel
      case t: TextBox => t.toJS.successNel
      case c: Chooser => c.toJS.successNel
      case w          => new Exception(s"Unconvertible widget type: ${w.getClass.getSimpleName}").failureNel
    }
  }

}
