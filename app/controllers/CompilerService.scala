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
  controllers.PlayUtil.EnhancedRequest

import
  models.{ local => mlocal, ModelSaver, Util },
    mlocal.NetLogoCompiler,
    Util.usingSource

object CompilerService extends Controller {

  private type DimsType = (Int, Int, Int, Int)

  private val MissingArgsMessage = "Your request must include either ('nlogo' and 'dimensions') or 'nlogo_url' as arguments."

  def compile = Action {
    implicit request =>

      val jsURLs = generateTortoiseLiteJsUrls()
      val argMap = request.extractArgMap

      val fromURL = maybeBuildFromURL(argMap, jsURLs, MissingArgsMessage) {
        url =>
          val nlogoContents = usingSource(_.fromURL(url))(_.mkString)
          NetLogoCompiler.fromNLogoFile(nlogoContents)._2
      }

      val fromSrcAndDims = maybeBuildFromSrcAndDims(argMap, jsURLs, MissingArgsMessage) {
        NetLogoCompiler.generateJS
      }

      (fromSrcAndDims orElse fromURL) fold (
        (nel => ExpectationFailed(nel.list.mkString("\n"))),
        (js  => Ok(js))
      )

  }

  def saveToHtml = Action {
    implicit request =>

      val jsURLs = generateTortoiseLiteJsUrls()
      val argMap = request.extractArgMap

      val fromURL = maybeBuildFromURL(argMap, jsURLs, MissingArgsMessage) {
        url => ModelSaver(url, jsURLs)
      }

      val fromSrcAndDims = maybeBuildFromSrcAndDims(argMap, jsURLs, MissingArgsMessage) {
        (source, dims) => ModelSaver(source, dims, jsURLs)
      }

      (fromSrcAndDims orElse fromURL) fold (
        (nel => ExpectationFailed(nel.list.mkString("\n"))),
        (js  => Ok(views.html.standaloneTortoise(js)))
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

  private def maybeBuildFromURL[T](argMap: Map[String, String], jsURLs: Seq[URL], errorStr: String)
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

  private def maybeBuildFromSrcAndDims[T](argMap: Map[String, String], jsURLs: Seq[URL], errorStr: String)
                                         (f: (String, DimsType) => T): ValidationNel[String, T] = {

    val sourceMaybe =
      argMap get "nlogo" map (
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

}
