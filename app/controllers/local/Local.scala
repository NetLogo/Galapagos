package controllers.local

import
  java.net.{ MalformedURLException, URL }

import
  scala.util.Try

import
  scalaz.Scalaz. { ToApplyOpsUnapply, ToValidationV }

import
  play.api.{ libs, mvc },
    libs.{ iteratee, json },
      iteratee.Enumerator,
      json.JsValue,
    mvc.{ Action, Controller, RequestHeader, ResponseHeader, SimpleResult, WebSocket }

import
  controllers.PlayUtil.EnhancedRequest

import
  models.{ local, Util },
    local.{ LocalInstance, ModelSaver },
    Util.usingSource

object Local extends Controller {

  private lazy val compatStr = usingSource(_.fromURL(getClass.getResource("/js/compat.js")))(_.mkString)
  private lazy val engineStr = usingSource(_.fromURL(getClass.getResource("/js/engine.js")))(_.mkString)

  def index = Action {
    implicit request =>
      Ok(views.html.local.client())
  }

  def handleSocketConnection() = WebSocket.async[JsValue] {
    implicit request => LocalInstance.join()
  }

  def compat = Action {
    implicit request => OkJS(compatStr)
  }

  def engine = Action {
    implicit request => OkJS(engineStr)
  }

  def saveToHtml = Action {
    implicit request =>

      val MissingArgsMessage = "Your request must include either ('nlogo' and 'dimensions') or 'nlogo_url' as arguments."

      val jsURLs = generateTortoiseLiteJsUrls()
      val argMap = request.extractArgMap

      val urlMaybe =
        argMap get "nlogo_url" map (
          _.successNel[String]
        ) getOrElse {
          MissingArgsMessage.failNel[String]
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

      val sourceMaybe =
        argMap get "nlogo" map (
          _.successNel[String]
        ) getOrElse {
          MissingArgsMessage.failNel[String]
        } flatMap {
          nlogo =>
            Try(new URL(nlogo)) map {
              url => usingSource(_.fromURL(url))(_.mkString.successNel[String])
            } recover {
              case ex: MalformedURLException => nlogo.successNel[String]
            } getOrElse {
              "An unknown error has occurred in processing your 'nlogo' value".failNel[String]
            }
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
          MissingArgsMessage.failNel[String]
        } flatMap {
          case DimensionsRegex(minX, maxX, minY, maxY) =>
            (minX.toInt, maxX.toInt, minY.toInt, maxY.toInt).successNel[String]
          case _ =>
            "Expected dimensions in the following format: [minX, maxX, minY, maxY]".failNel[(Int, Int, Int, Int)]
        }

      val fromSrcAndDims = (sourceMaybe |@| dimensionsMaybe) {
        (source, dimensions) => ModelSaver(source, dimensions, jsURLs)
      }

      (fromSrcAndDims orElse urlMaybe) fold (
        (nel  => ExpectationFailed(nel.list.mkString("\n"))),
        (js => Ok(views.html.standaloneTortoise(js)))
      )

  }

  private def OkJS(js: String) =
    SimpleResult(
      header = ResponseHeader(200, Map(CONTENT_TYPE -> "text/javascript")),
      body   = Enumerator(js.getBytes(play.Play.application.configuration.getString("application.defaultEncoding")))
    )

  private def generateTortoiseLiteJsUrls()(implicit request: RequestHeader): Seq[URL] = {

    val normalURLs = Seq(routes.Local.compat, routes.Local.engine)

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

}
