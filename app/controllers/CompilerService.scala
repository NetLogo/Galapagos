package controllers

import
  java.net.{ MalformedURLException, URL }

import
  scala.util.{ Try, matching },
    matching.Regex

import
  scalaz.{ NonEmptyList, Scalaz, Validation, ValidationNel },
    Scalaz.ToValidationOps,
    Validation.FlatMap.ValidationFlatMapRequested

import
  com.fasterxml.jackson.core.JsonProcessingException

import
  org.nlogo.{ core, tortoise },
    core.{ Model, Widget },
    tortoise.CompiledModel,
      CompiledModel.CompileResult

import
  play.api.{ cache, libs, mvc, Play },
    cache.Cache,
    libs.json.{ Json, JsObject },
      Json.toJsFieldJsValueWrapper,
    Play.current,
    mvc.{ Action, Controller, RequestHeader, Result }


import
  controllers.PlayUtil.EnhancedRequest

import
  models.{ CompilationFailure, CompilationSuccess, compile, json, ModelCompilationStatus, ModelSaver, ModelsLibrary, StatusCacher, Util },
    compile.{ CompileResponse, IDedValues, IDedValuesMap, IDedValuesSeq },
    json.{ WidgetReads, Writers },
      Writers.compileResponseWrites,
    ModelsLibrary.prettyFilepath,
    Util.usingSource,
    StatusCacher.AllBuiltInModelsCacheKey

object CompilerService extends Controller {

  /////////////
  // Actions //
  /////////////

  def compileURL   = genCompileAction(modelFromURL,   urlMissingMsg)
  def compileCode  = genCompileAction(modelFromCode,  codeMissingMsg)
  def compileNlogo = genCompileAction(modelFromNlogo, nlogoMissingMsg)

  def saveURL      = genSaveAction   (modelFromURL,   urlMissingMsg)
  def saveCode     = genSaveAction   (modelFromCode,  codeMissingMsg)
  def saveNlogo    = genSaveAction   (modelFromNlogo, nlogoMissingMsg)

  protected[controllers] type ModelMaker = (String, List[Widget], String) => ModelResultV
  protected[controllers] val modelFromURL: ModelMaker   = (url,   _, hostUri) =>
    fetchURL(url, hostUri) map (CompiledModel.fromNlogoContents(_))
  protected[controllers] val modelFromCode:  ModelMaker = (code,  widgets, _) =>
    CompiledModel.fromModel(Model(code, widgets)).successNel
  protected[controllers] val modelFromNlogo: ModelMaker = (nlogo, _, _)       =>
    CompiledModel.fromNlogoContents(nlogo).successNel

  protected[controllers] def genCompileAction(compileModel: ModelMaker, missingModelMsg: String) =
    Action { implicit request =>
      val argMap = toStringMap(request.extractBundle)

      val responseV = for {
        widgets      <- WidgetReads.parseWidgets(argMap.getOrElse("widgets", "[]"))
        modelStr     <- extractModelString(argMap, missingModelMsg)
        modelResult  <- compileModel(modelStr, widgets, request.host)
        commands     <- getIDedStmtsV(argMap, CommandsKey)
        reporters    <- getIDedStmtsV(argMap, ReportersKey)
      } yield CompileResponse.fromModel(modelResult, commands, reporters)

      responseV fold (nelResult(BadRequest), res => Ok(Json.toJson(res)))
    }

  protected[controllers] def getIDedStmtsV(argMap: Map[String, String], field: String): ValidationNel[String, IDedValues[String]] = {
    val malformedStmtsError = s"`$field` must be a JSON array of strings or JSON object with string values.".failureNel
    Try(Json.parse(argMap.getOrElse(field, "[]")).successNel).recover {
      case _: JsonProcessingException => malformedStmtsError
    }.get.flatMap { json =>
      val asSeq      = json.asOpt[Seq[String]]         map IDedValuesSeq.apply
      lazy val asMap = json.asOpt[Map[String, String]] map IDedValuesMap.apply
      asSeq orElse asMap map (_.successNel) getOrElse malformedStmtsError
    }
  }

  protected[controllers] def genSaveAction(compileModel: ModelMaker, missingModelMsg: String) =
    Action {
      implicit request =>

      val slurpURL = (url: String) => usingSource(_.fromURL(routes.Assets.at(url).absoluteURL()))(_.mkString)

      val stylesheets = Set("stylesheets/widgets.css",
                            "stylesheets/classic.css",
                            "stylesheets/netlogo-syntax.css",
                            "lib/codemirror/lib/codemirror.css")
      val css = stylesheets map slurpURL mkString "\n"

      val argMap  = toStringMap(request.extractBundle)
      val bundleV =
        for {
          modelStr    <- extractModelString(argMap, missingModelMsg)  leftMap nelResult(BadRequest)
          modelResult <- compileModel(modelStr, List(), request.host) leftMap nelResult(BadRequest)
          model       <- modelResult                                  leftMap nelResult(InternalServerError)
        } yield ModelSaver(model, generateTortoiseLiteJsUrls())

      bundleV.fold(
        identity,
        bundle => Ok(views.html.standaloneTortoise(
          bundle.modelJs, bundle.libsJs, css, bundle.widgets, bundle.nlogoCode, bundle.info)
        )
      )
    }

  def modelStatuses = Action {
    implicit request =>
      val resultJson =
        Cache.getOrElse(AllBuiltInModelsCacheKey)(Seq[String]())
             .map(genStatusJson)
             .foldLeft(Json.obj())(_ ++ _)
      Ok(Json.stringify(resultJson))
  }

  private def genStatusJson(filePath: String): JsObject = {
    Cache.get(filePath) match {
      case Some(CompilationSuccess(file)) =>
        Json.obj(prettyFilepath(file) -> Json.obj("status" -> "compiling"))
      case Some(CompilationFailure(file, errors)) =>
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
        routes.Assets.at("lib/ractive/ractive.js"),
        routes.Assets.at("lib/codemirror/lib/codemirror.js"),
        routes.Assets.at("lib/codemirror/addon/mode/simple.js"),
        routes.Local.engine
      )

    val assetURLs =
      Seq(
        "javascripts/TortoiseJS/agent/colors.js",
        "javascripts/TortoiseJS/agent/drawshape.js",
        "javascripts/TortoiseJS/agent/defaultshapes.js",
        "javascripts/TortoiseJS/agent/linkdrawer.js",
        "javascripts/TortoiseJS/agent/view.js",
        "javascripts/TortoiseJS/agent/editor.js",
        "javascripts/TortoiseJS/agent/info.js",
        "javascripts/TortoiseJS/agent/output.js",
        "javascripts/TortoiseJS/agent/console.js",
        "javascripts/TortoiseJS/agent/widgets.js",
        "javascripts/TortoiseJS/communication/connection.js",
        "javascripts/TortoiseJS/control/session-lite.js",
        "javascripts/plot/highchartsops.js"
      ) map (
        routes.Assets.at(_)
      )

    (normalURLs ++ assetURLs) map (route => new URL(route.absoluteURL()))

  }

  private def toStringMap(bundle: ParamBundle): Map[String, String] = {
    val fileMap = bundle.byteParams mapValues (str => new String(str, "ISO-8859-1"))
    bundle.stringParams ++ fileMap
  }

  private def nelResult[E](status: Status)(nel: NonEmptyList[E]): Result =
    status(nel.stream.mkString("\n\n"))

  private def extractModelString(argMap: Map[String, String], missingMsg: String): ValidationNel[String, String] =
    (argMap get ModelKey).fold(missingMsg.failureNel[String])(_.successNel[String])

  private def fetchURL(url: String, hostUri: String): ValidationNel[String, String] = {
    val locallyHostedRegex = new Regex(s"^https?://$hostUri/assets/([A-Za-z0-9%/]+\\.nlogo)$$", "file")
    Try {
      locallyHostedRegex.findFirstMatchIn(url).flatMap(m =>
        Assets.resourceNameAt("/public", m.group("file")).flatMap(Play.resource)
      ).getOrElse(new URL(url))
    } map {
      wellFormedURL => usingSource(_.fromURL(wellFormedURL))(_.mkString).successNel
    } recover {
      case _: MalformedURLException => s"'$url' is an invalid URL.".failureNel
    } getOrElse {
      s"An unknown error occurred while processing the URL '$url'. Make sure the url is publicly accessible.".failureNel
    }
  }

  // Outer validation indicates the validity of the model representation, whereas CompileResult indicates whether the
  // model compiled successfully. BCH 8/28/2014
  protected[controllers] type ModelResultV = ValidationNel[String, CompileResult[CompiledModel]]

  private val CommandsKey  = "commands"
  private val ModelKey     = "model"
  private val ReportersKey = "reporters"

  private val urlMissingMsg   = s"You must provide a `$ModelKey` parameter that contains the URL of an nlogo file."
  private val codeMissingMsg  = s"You must provide a `$ModelKey` parameter that contains the code from a NetLogo model."
  private val nlogoMissingMsg = s"You must provide a `$ModelKey` parameter that contains the contents of an nlogo file."

}
