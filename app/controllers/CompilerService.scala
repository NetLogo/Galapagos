package controllers

import
  java.net.{ MalformedURLException, URL }

import
  scala.util.Try

import
  scalaz.{ Scalaz, ValidationNel },
    Scalaz.{ ToApplyOpsUnapply, ToValidationV }

import
  play.api.mvc.{ Action, Controller, RequestHeader }

import 
  play.api.libs.json.Json

import
  controllers.PlayUtil.EnhancedRequest

import
  models.{ local => mlocal, ModelSaver, Util },
    mlocal.NetLogoCompiler,
    Util.usingSource

object CompilerService extends Controller {

  private type DimsType = (Int, Int, Int, Int)

  private val MissingArgsMsg = "Your request must include either ('netlogo_code' and 'dimensions') or 'nlogo_url' or 'nlogo' as arguments."
  private def BadStmtsMsg(stmtType: String) = s"$stmtType to be compiled should be formated as a JSON array of strings."

  def compile = Action {
    implicit request =>

      val argMap = request.extractArgMap

      val fromURL = maybeBuildFromURL(argMap, MissingArgsMsg) {
        url =>
          val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
          NetLogoCompiler.fromNLogoFile(nlogoContents)
      }

      val fromSrcAndDims = maybeBuildFromSrcAndDims(argMap, MissingArgsMsg) {
        (source, dims) => NetLogoCompiler.fromCodeAndDims(source, dims)
      }

      val fromNlogo = maybeBuildFromNlogo(argMap, MissingArgsMsg) {
        NetLogoCompiler.fromNLogoFile
      }

      val maybeCommands = maybeGetStmts(argMap, "commands", BadStmtsMsg("Commands"))
      val maybeReporters = maybeGetStmts(argMap, "reporters", BadStmtsMsg("Reporters"))
      val maybeCompilerAndJs = fromSrcAndDims orElse fromURL orElse fromNlogo
      val maybeCompiledCommands = (maybeCompilerAndJs |@| maybeCommands) {
        (compilerAndJs, commands) => commands map { cmd => compilerAndJs._1.runCommand(cmd)._2 }
      }
      val maybeCompiledReporters = (maybeCompilerAndJs |@| maybeReporters) {
        (compilerAndJs, reporters) => reporters map { cmd => compilerAndJs._1.runReporter(cmd)._2 }
      }

      val maybeResult = (maybeCompilerAndJs |@| maybeCompiledCommands |@| maybeCompiledReporters) {
        (compilerAndJs, commands, reporters) => createResponse(compilerAndJs._2, commands, reporters)
      }

      maybeResult fold (
        (nel    => ExpectationFailed(nel.list.mkString("\n"))),
        (result => Ok(result))
      )
  }

  def saveToHtml = Action {
    implicit request =>

      val jsURLs = generateTortoiseLiteJsUrls()
      val argMap = request.extractArgMap

      val fromURL = maybeBuildFromURL(argMap, MissingArgsMsg) {
        url => ModelSaver(url, jsURLs)
      }

      val fromSrcAndDims = maybeBuildFromSrcAndDims(argMap, MissingArgsMsg) {
        (source, dims) => ModelSaver(source, dims, jsURLs)
      }

      (fromSrcAndDims orElse fromURL) fold (
        nel => ExpectationFailed(nel.list.mkString("\n")),
        js  => Ok(views.html.standaloneTortoise(js))
      )

  }

  private def generateTortoiseLiteJsUrls()(implicit request: RequestHeader): Seq[URL] = {

    val normalURLs = Seq(local.routes.Local.compat, local.routes.Local.engine)

    val assetURLs =
      Seq(
        "javascripts/TortoiseJS/agent/agentmodel.js",
        "javascripts/TortoiseJS/agent/colors.js",
        "javascripts/TortoiseJS/agent/drawshape.js",
        "javascripts/TortoiseJS/agent/defaultshapes.js",
        "javascripts/TortoiseJS/agent/view.js",
        "javascripts/TortoiseJS/communication/connection.js",
        "javascripts/TortoiseJS/control/session-lite.js"
      ) map (
        controllers.routes.Assets.at(_)
      )

    (normalURLs ++ assetURLs) map (route => new URL(route.absoluteURL()))

  }

  private def maybeBuildFromURL[T](argMap: Map[String, String], errorStr: String)
                                  (f: (URL) => T): ValidationNel[String, T] =
    argMap get "nlogo_url" map (
      _.successNel
    ) getOrElse {
      errorStr.failNel
    } flatMap {
      nlogoURL =>
        Try(new URL(nlogoURL)) map f map (
          _.successNel
        ) recover {
          case ex: MalformedURLException => "Invalid 'nlogo_url' supplied (must be valid URL)".failNel
        } getOrElse {
          "An unknown error has occurred in processing your 'nlogo_url' value".failNel
        }
    }

  private def maybeBuildFromSrcAndDims[T](argMap: Map[String, String], errorStr: String)
                                         (f: (String, DimsType) => T): ValidationNel[String, T] = {

    val sourceMaybe =
      argMap get "netlogo_code" map (
        _.successNel
      ) getOrElse {
        errorStr.failNel
      }

    val DimensionsRegex = {
      val s = "\\s*"
      val n = "-?\\d+"
      s"""$s\\[($n),$s($n),$s($n),$s($n)\\]$s""".r
    }

    val dimensionsMaybe =
      argMap get "dimensions" map (
        _.successNel
      ) getOrElse {
        errorStr.failNel
      } flatMap {
        case DimensionsRegex(minX, maxX, minY, maxY) =>
          (minX.toInt, maxX.toInt, minY.toInt, maxY.toInt).successNel
        case _ =>
          "Expected dimensions in the following format: [minX, maxX, minY, maxY]".failNel
      }

    (sourceMaybe |@| dimensionsMaybe) {
      (source, dimensions) => f(source, dimensions)
    }

  }

  private def maybeBuildFromNlogo[T](argMap: Map[String, String], errorStr: String)
                                    (f: (String) => T): ValidationNel[String, T] = {
    val nlogoMaybe = argMap get "nlogo" map (_.successNel) getOrElse errorStr.failNel
    nlogoMaybe map {
      nlogo => f(nlogo)
    }
  }

  private def maybeGetStmts(argMap: Map[String, String], field: String, errorStr: String): ValidationNel[String, Seq[String]] =
    // TODO: Wrap exception in validation stuff.
    Json.parse(argMap get field getOrElse "[]").asOpt[Seq[String]] map (
      _.successNel
    ) getOrElse {
      errorStr.failNel
    }

  private def createResponse(compiledCode: String, compiledCommands: Seq[String], compiledReporters: Seq[String]): String =
    Json.stringify(Json.obj(
      "code" -> compiledCode,
      "commands" -> Json.toJson(compiledCommands),
      "reporters" -> Json.toJson(compiledReporters)
    ))
}

