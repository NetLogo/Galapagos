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
  models.ModelSaver

object CompilerService extends Controller {

  def saveToHtml = Action {
    implicit request =>

      val MissingArgsMessage = "Your request must include either ('nlogo' and 'dimensions') or 'nlogo_url' as arguments."

      val jsURLs = generateTortoiseLiteJsUrls()
      val argMap = request.extractArgMap

      val fromURL        = maybeBuildFromURL       (argMap, jsURLs, MissingArgsMessage)
      val fromSrcAndDims = maybeBuildFromSrcAndDims(argMap, jsURLs, MissingArgsMessage)

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

  private def maybeBuildFromURL(argMap: Map[String, String], jsURLs: Seq[URL], errorStr: String): ValidationNel[String, String] =
    argMap get "nlogo_url" map (
      _.successNel[String]
      ) getOrElse {
      errorStr.failNel[String]
    } flatMap {
      nlogoURL =>
        Try(new URL(nlogoURL)) map {
          url => ModelSaver(url, jsURLs).successNel[String]
        } recover {
          case ex: MalformedURLException => "Invalid 'nlogo_url' supplied (must be valid URL)".failNel[String]
        } getOrElse {
          "An unknown error has occurred in processing your 'nlogo_url' value".failNel[String]
        }
    }

  private def maybeBuildFromSrcAndDims(argMap: Map[String, String], jsURLs: Seq[URL], errorStr: String): ValidationNel[String, String] = {

    val sourceMaybe =
      argMap get "nlogo" map (
        _.successNel[String]
        ) getOrElse {
        errorStr.failNel[String]
      }

    val DimensionsRegex = {
      val s = "\\s*"
      val n = "-?\\d+"
      s"""$s[($n),$s($n),$s($n),$s($n)]$s""".r
    }

    val dimensionsMaybe =
      argMap get "dimensions" map (
        _.successNel[String]
        ) getOrElse {
        errorStr.failNel[String]
      } flatMap {
        case DimensionsRegex(minX, maxX, minY, maxY) =>
          (minX.toInt, maxX.toInt, minY.toInt, maxY.toInt).successNel[String]
        case _ =>
          "Expected dimensions in the following format: [minX, maxX, minY, maxY]".failNel[(Int, Int, Int, Int)]
      }

    (sourceMaybe |@| dimensionsMaybe) {
      (source, dimensions) => ModelSaver(source, dimensions, jsURLs)
    }

  }

}
