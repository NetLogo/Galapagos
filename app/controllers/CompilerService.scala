package controllers

import
  java.net.{ MalformedURLException, URL }

import
  scala.util.Try

import
  scalaz.{ Scalaz, ValidationNel },
    Scalaz.{ ToApplyOpsUnapply, ToValidationV }

import
  com.fasterxml.jackson.core.JsonProcessingException

import
  play.api.{ libs, mvc },
    libs.json.Json,
    mvc.{ Action, Controller, RequestHeader }

import
  controllers.PlayUtil.EnhancedRequest

import
  models.{ local => mlocal, ModelSaver, Util },
    mlocal.NetLogoCompiler,
    Util.usingSource

object CompilerService extends Controller {

  private val MissingArgsMsg = "Your request must include either 'nlogo_url' or 'nlogo' as arguments."
  private def BadStmtsMsg(stmtType: String) = s"$stmtType to be compiled should be formatted as a JSON array of strings."

  def compile = Action {
    implicit request =>

      val argMap = request.extractArgMap

      val fromURL = maybeBuildFromURL(argMap, MissingArgsMsg) {
        url =>
          val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
          NetLogoCompiler.fromNLogoFile(nlogoContents)
      }

      val fromNlogo = maybeBuildFromNlogo(argMap, MissingArgsMsg) {
        NetLogoCompiler.fromNLogoFile
      }

      val maybeCommands  = maybeGetStmts(argMap, "commands",  BadStmtsMsg("Commands"))
      val maybeReporters = maybeGetStmts(argMap, "reporters", BadStmtsMsg("Reporters"))

      val maybeResult = (fromURL orElse fromNlogo) flatMap {
        case (compiler, js) =>
          val maybeCompiledCommands  = maybeCommands  map {_ map { stmt => compiler.runCommand (stmt)._2 } }
          val maybeCompiledReporters = maybeReporters map {_ map { stmt => compiler.runReporter(stmt)._2 } }
          (maybeCompiledCommands |@| maybeCompiledReporters) {
            (commands, reporters) => createResponse(js, commands, reporters)
          }
      }

      maybeResult fold (
        nel    => ExpectationFailed(nel.list.mkString("\n")),
        result => Ok(result)
      )

  }

  def saveToHtml = Action {
    implicit request =>

      val jsURLs = generateTortoiseLiteJsUrls()

      val ParamBundle(argSeqMap, fileBytesMap) = request.extractBundle
      val argMap  = argSeqMap    mapValues (_.head)
      val fileMap = fileBytesMap mapValues (str => new String(str, "ISO-8859-1"))

      val fromURL = maybeBuildFromURL(argMap, MissingArgsMsg) {
        url => ModelSaver(url, jsURLs)
      }

      val fromNlogo = maybeBuildFromNlogo(fileMap, MissingArgsMsg) {
        contents => ModelSaver(contents, jsURLs)
      }

      (fromURL orElse fromNlogo) fold (
        nel    => ExpectationFailed(nel.list.mkString("\n")),
        bundle => Ok(views.html.standaloneTortoise(bundle.js, bundle.colorizedNlogoCode))
      )

  }

  private def generateTortoiseLiteJsUrls()(implicit request: RequestHeader): Seq[URL] = {

    val normalURLs =
      Seq(
        local.routes.Local.compat,
        routes.WebJarAssets.at(WebJarAssets.locate("mori.js")),
        routes.WebJarAssets.at(WebJarAssets.locate("lodash.js")),
        local.routes.Local.engine
      )

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
          case _: MalformedURLException => "Invalid 'nlogo_url' supplied (must be valid URL)".failNel
        } getOrElse {
          "An unknown error has occurred in processing your 'nlogo_url' value".failNel
        }
    }

  private def maybeBuildFromNlogo[T](argMap: Map[String, String], errorStr: String)
                                    (f: (String) => T): ValidationNel[String, T] = {
    val nlogoMaybe = argMap get "nlogo" map (_.successNel) getOrElse errorStr.failNel
    nlogoMaybe map f
  }

  private def maybeGetStmts(argMap: Map[String, String], field: String, errorStr: String): ValidationNel[String, Seq[String]] = {
    val parsedMaybe = Try(Json.parse(argMap.getOrElse(field, "[]")).successNel).recover {
      case _: JsonProcessingException => errorStr.failNel
    }.get
    parsedMaybe flatMap (_.asOpt[Seq[String]] map (_.successNel) getOrElse errorStr.failNel)
  }

  private def createResponse(compiledCode: String, compiledCommands: Seq[String], compiledReporters: Seq[String]): String =
    Json.stringify(Json.obj(
      "code"      -> compiledCode,
      "commands"  -> Json.toJson(compiledCommands),
      "reporters" -> Json.toJson(compiledReporters)
    ))
}

