package controllers

import
  java.net.{ MalformedURLException, URL }

import
  scala.util.Try

import
  scalaz.{ Scalaz, Validation, ValidationNel },
    Scalaz.{ ToApplyOpsUnapply, ToValidationOps },
    Validation.FlatMap.ValidationFlatMapRequested

import
  com.fasterxml.jackson.core.JsonProcessingException

import
  org.nlogo.tortoise.CompiledModel

import
  play.api.{Play, cache, libs, mvc},
    cache.Cache,
    libs.json.{ Json, JsObject },
    Play.current,
    mvc.{ Action, Controller, RequestHeader }

import
  controllers.PlayUtil.EnhancedRequest

import
  models.{ ModelSaver, Util, ModelsLibrary },
    Util.usingSource,
    ModelsLibrary.prettyFilepath,
    models.remote.ModelLibraryCompiler.Messages.{ModelCompilationSuccess, ModelCompilationFailure},
    models.remote.StatusCacher._

object CompilerService extends Controller {

  private val MissingArgsMsg = "Your request must include either 'nlogo_url' or 'nlogo' as arguments."
  private def BadStmtsMsg(stmtType: String) = s"$stmtType to be compiled should be formatted as a JSON array of strings."

  def compile = Action {
    implicit request =>

      val argMap = request.extractArgMap

      val fromURL = maybeBuildFromURL(argMap, MissingArgsMsg) {
        url =>
          val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
          CompiledModel.fromNlogoContents(nlogoContents)
      }

      val fromNlogo = maybeBuildFromNlogo(argMap, MissingArgsMsg) {
        CompiledModel.fromNlogoContents(_)
      }

      val maybeCommands  = maybeGetStmts(argMap, "commands",  BadStmtsMsg("Commands"))
      val maybeReporters = maybeGetStmts(argMap, "reporters", BadStmtsMsg("Reporters"))

      ((fromNlogo orElse fromURL) |@| maybeCommands |@| maybeReporters) {
        case (model, commands, reporters) => (model, commands, reporters)
      } fold (
        nel => ExpectationFailed(nel.list.mkString("\n")),
        {
          case (compileResult, commands, reporters) =>
            import Scalaz._
            compileResult flatMap {
              case model @ CompiledModel(js, m, _, _, _) =>
                val commandVs  = commands.toList. map(model.compileCommand (_)).sequence
                val reporterVs = reporters.toList.map(model.compileReporter(_)).sequence
                (commandVs |@| reporterVs) {
                  (cs, rs) => createResponse(js, cs, rs, m.info)
                }
            } fold (
              nel => InternalServerError(nel.list.mkString("\n")),
              result => Ok(result)
            )
        }
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

      (fromNlogo orElse fromURL) fold (
        nel     => ExpectationFailed(nel.list.mkString("\n")),
        bundleV => bundleV fold (
          nel    => InternalServerError(nel.list.mkString("\n")),
          bundle => Ok(views.html.standaloneTortoise(bundle.js, bundle.colorizedNlogoCode, bundle.info))
        )
      )

  }

  def modelStatuses = Action {
    implicit request =>
      val resultJson: JsObject = Cache
        .getOrElse(AllBuiltInModelsCacheKey)(Seq[String]())
        .map(modelCompilationStatus)
        .foldLeft(Json.obj())(_ ++ _)

      Ok(Json.stringify(resultJson))
  }

  private def modelCompilationStatus(filePath: String): JsObject = {
    Cache.get(filePath) match {
      case Some(ModelCompilationSuccess(file)) =>
        Json.obj(prettyFilepath(file) -> Json.obj("status" -> "compiling"))
      case Some(ModelCompilationFailure(file, errors)) =>
        Json.obj(prettyFilepath(file) -> Json.obj(
          "status" -> "not_compiling",
          "errors" -> errors.foldLeft("")(_ + _.toString)))
      case _ =>
        Json.obj(prettyFilepath(filePath) -> Json.obj("status" -> "unknown"))
    }
  }

  private def generateTortoiseLiteJsUrls()(implicit request: RequestHeader): Seq[URL] = {

    val normalURLs =
      Seq(
        routes.Assets.at("lib/markdown-js/markdown.js"),
        routes.Assets.at("lib/highcharts/adapters/standalone-framework.js"),
        routes.Assets.at("lib/highcharts/highcharts.js"),
        routes.Assets.at("lib/highcharts/modules/exporting.js"),
        local.routes.Local.engine
      )

    val assetURLs =
      Seq(
        "javascripts/TortoiseJS/agent/agentmodel.js",
        "javascripts/TortoiseJS/agent/colors.js",
        "javascripts/TortoiseJS/agent/drawshape.js",
        "javascripts/TortoiseJS/agent/defaultshapes.js",
        "javascripts/TortoiseJS/agent/view.js",
        "javascripts/TortoiseJS/agent/widgets.js",
        "javascripts/TortoiseJS/communication/connection.js",
        "javascripts/TortoiseJS/control/session-lite.js",
        "javascripts/plot/highchartsops.js"
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
      errorStr.failureNel
    } flatMap {
      nlogoURL =>
        Try(new URL(nlogoURL)) map f map (
          _.successNel
        ) recover {
          case _: MalformedURLException => "Invalid 'nlogo_url' supplied (must be valid URL)".failureNel
        } getOrElse {
          "An unknown error has occurred in processing your 'nlogo_url' value".failureNel
        }
    }

  private def maybeBuildFromNlogo[T](argMap: Map[String, String], errorStr: String)
                                    (f: (String) => T): ValidationNel[String, T] = {
    val nlogoMaybe = argMap get "nlogo" map (_.successNel) getOrElse errorStr.failureNel
    nlogoMaybe map f
  }

  private def maybeGetStmts(argMap: Map[String, String], field: String, errorStr: String): ValidationNel[String, Seq[String]] = {
    val parsedMaybe = Try(Json.parse(argMap.getOrElse(field, "[]")).successNel).recover {
      case _: JsonProcessingException => errorStr.failureNel
    }.get
    parsedMaybe flatMap (_.asOpt[Seq[String]] map (_.successNel) getOrElse errorStr.failureNel)
  }

  private def createResponse(compiledCode: String, compiledCommands: Seq[String],
                             compiledReporters: Seq[String], info: String): String =
    Json.stringify(Json.obj(
      "code"      -> compiledCode,
      "commands"  -> Json.toJson(compiledCommands),
      "reporters" -> Json.toJson(compiledReporters),
      "info"      -> info
    ))
}

