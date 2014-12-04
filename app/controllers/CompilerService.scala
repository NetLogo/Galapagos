package controllers

import
  java.net.{ MalformedURLException, URL }

import
  scala.util.Try

import
  scalaz.{ NonEmptyList, Scalaz, Validation, ValidationNel },
    Scalaz.ToValidationOps,
    Validation.FlatMap.ValidationFlatMapRequested

import
  com.fasterxml.jackson.core.JsonProcessingException

import
  org.nlogo.{ api, core, tortoise },
    api.CompilerException,
    core.{Model, Widget},
    tortoise.CompiledModel,
      CompiledModel.CompileResult

import
  play.api.{ cache, libs, mvc, Play },
    cache.Cache,
    libs.json.{ Json, JsObject, Writes },
      Json.toJsFieldJsValueWrapper,
    Play.current,
    mvc.{ Action, Controller, RequestHeader, Result }

import
  controllers.PlayUtil.EnhancedRequest

import
  models.{ json, local => mlocal, core => mcore },
    json.{CompileWrites, WidgetReads},
      CompileWrites._,
      WidgetReads._,
    mcore.{ ModelsLibrary, Util },
      ModelsLibrary.prettyFilepath,
      Util.usingSource,
    mlocal.{ CompilationFailure, CompilationSuccess, CompiledWidget, ModelSaver, StatusCacher },
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

  protected[controllers] type ModelMaker = (String, List[Widget]) => ModelResultV
  protected[controllers] val modelFromURL:   ModelMaker = (url,   _)       =>
    fetchURL(url) map (CompiledModel.fromNlogoContents(_))
  protected[controllers] val modelFromCode:  ModelMaker = (code,  widgets) =>
    CompiledModel.fromModel(Model(code, widgets)).successNel
  protected[controllers] val modelFromNlogo: ModelMaker = (nlogo, _)       =>
    CompiledModel.fromNlogoContents(nlogo).successNel


  protected[controllers] def genCompileAction(compileModel: ModelMaker, missingModelMsg: String) =
    Action { implicit request =>
      val argMap = toStringMap(request.extractBundle)

      val responseV = for {
        widgets      <- parseWidgets(argMap.getOrElse("widgets", "[]"))
        modelStr     <- extractModelString(argMap, missingModelMsg)
        modelResult  <- compileModel(modelStr, widgets)
        commands     <- getIDedStmtsV(argMap, commandsKey)
        reporters    <- getIDedStmtsV(argMap, reportersKey)
      } yield compile(modelResult, commands, reporters)

      responseV fold (nelResult(BadRequest), res => Ok(Json.toJson(res)))
    }

  protected[controllers] def parseWidgets(json: String): ValidationNel[String, List[Widget]] =
    Json.parse(json).validate[List[Widget]].fold(
      errors  => errors.mkString("\n").failureNel,
      widgets => widgets.successNel
    )

  protected[controllers] def compile(modelResult: CompileResult[CompiledModel],
                                     commands:    IDedValues[String],
                                     reporters:   IDedValues[String]): CompileResponse = {
    val failedMsg   = "Model failed to compile"
    val modelFailed = new CompilerException(failedMsg, 0, 0, "").failureNel[String]
    CompileResponse(modelResult map       (_.compiledCode),
                    modelResult map       (_.model.info) getOrElse failedMsg,
                    modelResult map       (_.model.code) getOrElse failedMsg,
                    modelResult map       (m => m.model.widgets map CompiledWidget.compile(m)) getOrElse Seq(),
                    commands    mapValues (s => modelResult map (_.compileCommand (s)) getOrElse modelFailed),
                    reporters   mapValues (s => modelResult map (_.compileReporter(s)) getOrElse modelFailed))
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

      val stylesheets = Set("stylesheets/widgets.css", "stylesheets/classic.css")
      val css         = stylesheets map slurpURL mkString "\n"

      val argMap  = toStringMap(request.extractBundle)
      val bundleV =
        for {
          modelStr    <- extractModelString(argMap, missingModelMsg) leftMap nelResult(BadRequest)
          modelResult <- compileModel(modelStr, List())              leftMap nelResult(BadRequest)
          model       <- modelResult                                 leftMap nelResult(InternalServerError)
        } yield ModelSaver(model, generateTortoiseLiteJsUrls())

      bundleV.fold(
        identity,
        bundle => Ok(views.html.local.standaloneTortoise(
          bundle.modelJs, bundle.libsJs, css, bundle.widgets, bundle.colorizedNlogoCode, bundle.info)
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
        local.routes.Local.engine
      )

    val assetURLs =
      Seq(
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

  private def toStringMap(bundle: ParamBundle): Map[String, String] = {
    val fileMap = bundle.byteParams mapValues (str => new String(str, "ISO-8859-1"))
    bundle.stringParams ++ fileMap
  }

  private def nelResult[E](status: Status)(nel: NonEmptyList[E]): Result =
    status(nel.stream.mkString("\n\n"))

  private def extractModelString(argMap: Map[String, String], missingMsg: String): ValidationNel[String, String] =
    (argMap get modelKey).fold(missingMsg.failureNel[String])(_.successNel[String])

  private def fetchURL(url: String): ValidationNel[String, String] = {
    Try(new URL(url)) map {
      wellFormedURL => usingSource(_.fromURL(wellFormedURL))(_.mkString).successNel
    } recover {
      case _: MalformedURLException => s"'$url' is an invalid URL.".failureNel
    } getOrElse {
      s"An unknown error occurred while processing the URL '$url'. Make sure the url is publicly accessible.".failureNel
    }
  }

  // Outer validation indicates the validity of the model representation, whereas CompileResult indicates whether the
  // model compiled successfully. BCH 8/28/2014
  protected[controllers] type ModelResultV  = ValidationNel[String, CompileResult[CompiledModel]]

  protected[controllers] type CompiledStmts = IDedValues[CompileResult[String]]

  protected[controllers] case class CompileResponse(model:     CompileResult[String],
                                                    info:      String,
                                                    code:      String,
                                                    widgets:   Seq[CompiledWidget[Widget]],
                                                    commands:  CompiledStmts,
                                                    reporters: CompiledStmts)

  // We allow users to pass in commands and reporters as either arrays or maps.
  // Either way, we preserve keys/ordering with the responses. We can't just do
  // the responses as maps with integer keys as you'd lose commands.length on
  // the javascript side.
  // BCH 11/11/2014
  protected[controllers] sealed trait IDedValues[T] {
    def mapValues[U](f: (T) => U): IDedValues[U]
  }
  protected[controllers] case class IDedValuesMap[T](map: Map[String, T]) extends IDedValues[T] {
    override def mapValues[U](f: (T) => U): IDedValues[U] = map.mapValues(f)
  }
  protected[controllers] case class IDedValuesSeq[T](seq: Seq[T]) extends IDedValues[T] {
    override def mapValues[U](f: (T) => U): IDedValues[U] = seq.map(f)
  }
  protected[controllers] implicit final def mapToIDedValues[T](map: Map[String, T]): IDedValuesMap[T] = IDedValuesMap(map)
  protected[controllers] implicit final def seqToIDedValues[T](seq: Seq[T]):         IDedValuesSeq[T] = IDedValuesSeq(seq)

  ///////////////////////////
  // JSON Writes implicits //
  ///////////////////////////
  protected[controllers] implicit val compileResponseWrites: Writes[CompileResponse] =
    Writes(
      (response: CompileResponse) => Json.obj(
        modelKey     -> response.model,
        infoKey      -> response.info,
        codeKey      -> response.code,
        widgetsKey   -> response.widgets,
        commandsKey  -> response.commands,
        reportersKey -> response.reporters
      )
    )

  protected[controllers] implicit val compiledStmtsWrites: Writes[CompiledStmts] =
    Writes {
      (_: CompiledStmts) match {
        case IDedValuesMap(map) => Json.toJson(map)
        case IDedValuesSeq(seq) => Json.toJson(seq)
      }
    }

  protected[controllers] val modelKey     = "model"
  protected[controllers] val infoKey      = "info"
  protected[controllers] val codeKey      = "code"
  protected[controllers] val commandsKey  = "commands"
  protected[controllers] val reportersKey = "reporters"
  protected[controllers] val widgetsKey   = "widgets"


  private val urlMissingMsg   =
    s"You must provide a `$modelKey` parameter that contains the URL of an nlogo file."
  private val codeMissingMsg  =
    s"You must provide a `$modelKey` parameter that contains the code from a NetLogo model."
  private val nlogoMissingMsg =
    s"You must provide a `$modelKey` parameter that contains the contents of an nlogo file."
}
