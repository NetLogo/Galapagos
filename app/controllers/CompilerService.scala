// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  java.io.{ Serializable => JSerializable }

import
  javax.inject.Inject

import
  scalaz.{ Scalaz, Validation, ValidationNel },
    Scalaz.ToValidationOps,
    Validation.FlatMap.ValidationFlatMapRequested

import
  play.api.{ cache, Environment, mvc },
    cache.{ NamedCache, SyncCacheApi },
    mvc.{ AbstractController, ControllerComponents, Request }
import controllers.{ Assets => PlayAssets }

import CompilerService.{ ArgMap, CodeKey, CommandsKey, ModelKey, ModelResultV, ReportersKey }

class CompilerService @Inject() (
  @NamedCache("compilation-statuses") override protected val cache: SyncCacheApi,
  components: ControllerComponents,
  override protected val environment: Environment
)(implicit assetsFinder: AssetsFinder) extends AbstractController(components)
  with EnvironmentHolder
  with CacheProvider
  with ModelStatusHandler
  with RequestResultGenerator
  with ResourceSender
{

  import
    controllers.PlayUtil.EnhancedRequest

  import
    scalaz.NonEmptyList

  import
    org.nlogo.{ core, tortoise },
      core.CompilerException,
      tortoise.compiler.{ CompiledModel, Compiler }

  import
    play.api.mvc.{ Action => ActionType, AnyContent, Result }

  import
    CompilationRequestHandler.{ generateFromCode, generateFromNlogo, generateFromUrl => gfu, ModelObject, ModelResult, ModelText }

  val compiler = new Compiler()

  private val generateFromUrl = (argMap: ArgMap, url: String) => gfu(argMap, url)(using environment, assetsFinder)

  def compileURL:   ActionType[AnyContent] = genCompileAction(generateFromUrl,   jsonResult)
  def compileCode:  ActionType[AnyContent] = genCompileAction(generateFromCode,  jsonResult)
  def compileNlogo: ActionType[AnyContent] = genCompileAction(generateFromNlogo, jsonResult)

  def exportCode: ActionType[AnyContent] = genCompileAction(generateFromCode, exportResult)

  def tortoiseCompilerJs:    ActionType[AnyContent] = Action { replyWithResource(environment)("tortoise-compiler.js")("text/javascript") }

  def tortoiseCompilerJsMap: ActionType[AnyContent] = Action { replyWithResource(environment)("tortoise-compiler.js.map")("application/octet-stream") }

  private def genCompileAction(generateModel: (ArgMap, String) => ModelResult, generateResult: (ArgMap, ModelResultV) => Result) =
    Action({
      implicit request: Request[AnyContent] =>
        val argMap = toStringMap(request.extractBundle)
        val model = generateModel(argMap, request.host).flatMap {
          case ModelObject(m)  => CompiledModel.fromModel(m, compiler).successNel[String]
          case ModelText(text) => stringifyNonCompilerExceptions(CompiledModel.fromNlogoXMLContents(text, compiler))
        }
        generateResult(argMap, model)
    })

  private def stringifyNonCompilerExceptions(v: ValidationNel[Exception, CompiledModel]): ModelResultV = {
    def liftCompilerExceptions(nel: NonEmptyList[Exception]): ModelResultV = {
      val (ces, es) =
        nel.list.foldLeft((List.empty[CompilerException], List.empty[Exception])) {
          case ((ces, es), ce: CompilerException) => (ces :+ ce, es)
          case ((ces, es), e:  Exception)         => (ces,       es :+ e)
        }
      val messages = es.map(_.getMessage)
      messages.headOption.map {
        h => NonEmptyList(h, messages.tail*).failure
      }.getOrElse {
        NonEmptyList(ces.head, ces.tail*).failure.successNel[String]
      }
    }
    v.fold(liftCompilerExceptions, _.successNel[CompilerException].successNel[String])
  }

  private def toStringMap(bundle: ParamBundle): ArgMap = {
    val fileMap = bundle.byteParams.view.mapValues(str => new String(str, "ISO-8859-1"))
    (bundle.stringParams ++ fileMap).toMap
  }
}


private[controllers] trait EnvironmentHolder {
  protected def environment: Environment
}

private[controllers] object CompilerService {

  import
    org.nlogo.tortoise.compiler.CompiledModel,
      CompiledModel.CompileResult

  // Outer validation indicates the validity of the model representation, whereas CompileResult indicates whether the
  // model compiled successfully. BCH 8/28/2014
  type ArgMap       = Map[String, String]
  type ModelResultV = ValidationNel[String, CompileResult[CompiledModel]]

  val CodeKey      = "code"
  val CommandsKey  = "commands"
  val ModelKey     = "model"
  val ReportersKey = "reporters"

}

private[controllers] object CompilationRequestHandler {

  import
    java.net.{ MalformedURLException, URL }

  import
    play.api.libs.json.Json

  import
    scala.util.Try

  import
    scalaz.NonEmptyList

  import
    org.nlogo.{ core, tortoise },
      core.{ Model, Shape },
        Shape.{ LinkShape, VectorShape },
      tortoise.compiler.{ json => tortoisejson },
        tortoisejson.{ ShapeToJsonConverters, TortoiseJson },
          ShapeToJsonConverters.{ readLinkShapes, readVectorShapes }

  import
    models.{ compile, json, Util },
      compile.CompileWidgets,
      json.JsonConverter,
        JsonConverter.{ toTortoise => toTortoiseJson },
      Util.usingSource

  sealed trait ModelArgument
  case class ModelObject(model: Model) extends ModelArgument
  case class ModelText(text: String)   extends ModelArgument

  type ModelResult = ValidationNel[String, ModelArgument]

  def generateFromUrl(argMap: ArgMap, hostUri: String)(implicit environment: Environment, assetsFinder: AssetsFinder): ModelResult =
    extractModelString(argMap, urlMissingMsg).flatMap(url => fetchURL(url, hostUri) map ModelText.apply)

  def generateFromCode(argMap: ArgMap, hostUri: String): ModelResult = {
    val info = argMap.getOrElse("info", "")
    for {
      widgets      <- CompileWidgets(argMap.getOrElse("widgets", "[]"))
      turtleShapes <- extractShapes[VectorShape]("turtleShapes", readVectorShapes, Model.defaultTurtleShapes)(argMap)
      linkShapes   <- extractShapes[LinkShape](  "linkShapes",   readLinkShapes,   Model.defaultLinkShapes  )(argMap)
      code         <- (argMap get CodeKey).fold(codeMissingMsg.failureNel[String])(_.successNel[String])
      model        <- Validation.fromTryCatchThrowable[Model, RuntimeException](
        Model(code, widgets, info = info, turtleShapes = turtleShapes, linkShapes = linkShapes))
        .leftMap(e => NonEmptyList(e.getMessage))
    } yield ModelObject(model)
  }

  def generateFromNlogo(argMap: ArgMap, hostUri: String): ModelResult =
    extractModelString(argMap, nlogoMissingMsg) map ModelText.apply

  private def fetchURL(url: String, hostUri: String)(implicit environment: Environment, assetsFinder: AssetsFinder): ValidationNel[String, String] = {
    val LocalHostRegex = s"^https?://$hostUri/assets/([A-Za-z0-9%/]+\\.nlogo)$$".r
    Try {
      (url match {
        case LocalHostRegex(file) => environment.resource(assetsFinder.findAssetPath("/public", file))
        case _                    => None
      }).getOrElse(new URL(url))
    } map {
      wellFormedURL => usingSource(_.fromURL(wellFormedURL))(_.mkString).successNel[String]
    } recover {
      case _: MalformedURLException => s"'$url' is an invalid URL.".failureNel
    } getOrElse {
      s"An unknown error occurred while processing the URL '$url'. Make sure the url is publicly accessible.".failureNel
    }
  }

  private def extractModelString(argMap: ArgMap, missingMsg: String): ValidationNel[String, String] =
    (argMap get ModelKey).fold(missingMsg.failureNel[String])(_.successNel[String])

  private val urlMissingMsg   = s"You must provide a `$ModelKey` parameter that contains the URL of an nlogo file."
  private val codeMissingMsg  = s"You must provide a `$CodeKey` parameter that contains the code from a NetLogo model."
  private val nlogoMissingMsg = s"You must provide a `$ModelKey` parameter that contains the contents of an nlogo file."

  private def extractShapes[T](key: String, parseShapes: TortoiseJson => ValidationNel[String, Seq[T]], default: Seq[T])
                              (argMap: Map[String, String]): ValidationNel[String, Seq[T]] = {
    val parsedJson = argMap.get(key) map Json.parse map toTortoiseJson map parseShapes map(_.map(_.toList))
    parsedJson getOrElse default.successNel
  }
}

private[controllers] trait RequestResultGenerator {

  self: AbstractController & EnvironmentHolder =>

  import
    java.net.URL

  import
    scala.util.Try

  import
    scalaz.NonEmptyList

  import
    com.fasterxml.jackson.core.JsonProcessingException

  import
    play.api.{ libs, mvc },
      libs.json.{ JsArray, Json },
      mvc.Result

  import
    controllers.Local.{ enginePath => engineJsPath }

  import
    models.{ compile, json, ModelSaver, Util },
      compile.{ CompileResponse, IDedValues, IDedValuesMap, IDedValuesSeq },
      json.Writers.compileResponseWrites,
      Util.usingSource

  protected def jsonResult(argMap: ArgMap, modelV: ModelResultV): Result =
    modelV.flatMap {
      model =>
        for {
          commands  <- getIDedStmtsV(argMap, CommandsKey)
          reporters <- getIDedStmtsV(argMap, ReportersKey)
        } yield CompileResponse.fromModel(model, commands, reporters)
    }.fold(jsonNelResult(BadRequest), res => Ok(Json.toJson(res)))

  protected def exportResult(argMap: ArgMap, modelV: ModelResultV): Result = {

    val filename =
      argMap.get("filename")
        .map(name => if (name.endsWith(".nlogo")) name else s"$name.nlogo")
        .getOrElse("export.nlogo")

    val compiledModelV = modelV flatMap CompileResponse.exportNlogoXML leftMap (_.map(ex => ex: JSerializable))

    compiledModelV.fold(
      nelResult(BadRequest),
      res => Ok(res).withHeaders(
        CONTENT_TYPE        -> TEXT,
        CONTENT_DISPOSITION -> s"""attachment; filename="$filename""""))

  }

  private def genCSS: String = {

    val slurpURL =
      (url: String) =>
        environment.resource(url)
          .map(assetUrl => usingSource(_.fromURL(assetUrl))(_.mkString))
          .getOrElse(throw new Exception(s"Missing stylesheet $url"))

    val stylesheets =
      Set(
        "/public/stylesheets/classes.css",
        "/public/stylesheets/widgets.css",
        "/public/stylesheets/info.css",
        "/public/stylesheets/ui-editor.css",
        "/public/stylesheets/netlogoweb.css",
        "/public/stylesheets/netlogo-syntax.css",
        "/public/codemirror/lib/codemirror.css",
        "/public/codemirror/addon/dialog/dialog.css"
      )

    stylesheets map slurpURL mkString "\n"

  }

  private def getIDedStmtsV(argMap: ArgMap, field: String): ValidationNel[String, IDedValues[String]] = {
    val malformedStmtsError = s"`$field` must be a JSON array of strings or JSON object with string values.".failureNel
    Try(Json.parse(argMap.getOrElse(field, "[]")).successNel[String]).recover {
      case _: JsonProcessingException => malformedStmtsError
    }.get.flatMap {
      json =>
        val asSeq = json.asOpt[Seq[String]]         map IDedValuesSeq.apply
        val asMap = json.asOpt[Map[String, String]] map IDedValuesMap.apply
        asSeq orElse asMap map (_.successNel[String]) getOrElse malformedStmtsError
    }
  }

  private def nelResult[E](status: Status)(nel: NonEmptyList[E]): Result =
    status(nel.stream.mkString("\n\n"))

  private def jsonNelResult(status: Status)(nel: NonEmptyList[String]): Result = {
    val errors = JsArray(nel.map(s => Json.obj("message" -> s)).list.toList.toSeq)
    val result = Json.obj("success" -> false, "result" -> errors)
    status(Json.obj(
      "model"    -> result,
      "commands" -> Json.arr(result)))
  }

}

private[controllers] trait ModelStatusHandler {

  self: AbstractController & CacheProvider =>

  import
    play.api.{ libs, mvc },
      libs.json.{ Json, JsObject },
      mvc.{ Action => ActionType, AnyContent }

  import
    models.{ CompilationFailure, CompilationSuccess, ModelCompilationStatus, ModelsLibrary, StatusCacher },
      ModelsLibrary.prettyFilepath,
      StatusCacher.AllBuiltInModelsCacheKey

  def modelStatuses: ActionType[AnyContent] = Action {
    implicit request =>
      val resultJson =
        cache.get[Seq[String]](AllBuiltInModelsCacheKey).getOrElse(Seq[String]())
          .map(genStatusJson)
          .foldLeft(Json.obj())(_ ++ _)
      Ok(Json.stringify(resultJson))
  }

  private def genStatusJson(filePath: String): JsObject = {
    cache.get[ModelCompilationStatus](filePath).map {
      case CompilationSuccess(file) =>
        Json.obj(prettyFilepath(file) -> Json.obj("status" -> "compiling"))
      case CompilationFailure(file, errors) =>
        Json.obj(prettyFilepath(file) -> Json.obj(
          "status" -> "not_compiling",
          "errors" -> errors.foldLeft("")(_ + _.toString)))
    }.getOrElse {
      Json.obj(prettyFilepath(filePath) -> Json.obj("status" -> "unknown"))
    }
  }

}

private[controllers] trait CacheProvider {
  protected def cache: SyncCacheApi
}
