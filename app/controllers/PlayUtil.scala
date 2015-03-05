package controllers

import models.Util

import
  scala.io.Codec

import
  play.api.{ libs, Logger, mvc },
    libs.json._,
    mvc.{ AnyContent, Request }

import
  Util.{ noneIfEmpty, usingSource }

object PlayUtil {

  implicit class EnhancedRequest(request: Request[AnyContent]) {

    def extractArgMap: Map[String, String] = extractBundle.stringParams

    // Try _really_ hard to parse the body into JSON (pretty much the only thing I don't try is XML conversion)
    def extractJSONOpt: Option[JsValue] = {
      val body = request.body
      body.asJson orElse {
        try
          body.asText orElse {
            body.asRaw flatMap (_.asBytes() map (new String(_)))
          } map Json.parse
        catch {
          case ex: Exception =>
            Logger.info("Failed to parse text into JSON", ex)
            None
        }
      } orElse (
        paramMap2JSON(extractBundle.stringSeqParams)
      )
    }

    // If Play actually made a good-faith effort at parameter extraction, I wouldn't have to go through this rubbish... --JAB 10/3/13
    def extractBundle: ParamBundle =
      request.body.asMultipartFormData map {
        formData =>
          val fileKVs = formData.files map {
            formFile =>
              val file = formFile.ref.file
              val arr  =
                if (file.length > 20E6.toLong)
                  "UPLOADED FILE TOO LARGE".getBytes
                else
                  usingSource(_.fromFile(file)(Codec.ISO8859))(_.map(_.toByte).toArray)
              (formFile.key, arr)
          }
          ParamBundle(formData.asFormUrlEncoded, fileKVs.toMap)
      } orElse {
        request.body.asFormUrlEncoded flatMap (noneIfEmpty(_)) map (ParamBundle(_))
      } orElse {
        Option(request.queryString) map (ParamBundle(_))
      } getOrElse {
        ParamBundle(Map(), Map())
      }

    private def stringSeq2JSONOpt(seq: Seq[String]): Option[JsValue] = {

      def generousParse(str: String): JsValue =
        try Json.parse(str)
        catch {
          case ex: Exception => JsString(str) // Ehh... --JAB 10/3/13
        }

      seq match {
        case Seq()  => None
        case Seq(h) => Option(generousParse(h))
        case s      => Option(new JsArray(s map generousParse))
      }

    }

    private def paramMap2JSON(paramMap: Map[String, Seq[String]]): Option[JsValue] = {
      val parsedParams    = paramMap mapValues stringSeq2JSONOpt
      val validatedParams = parsedParams collect { case (k, Some(v)) => (k, v) }
      noneIfEmpty(validatedParams) map (params => JsObject(params.toSeq))
    }

  }

}

case class ParamBundle(stringSeqParams: Map[String, Seq[String]], byteParams: Map[String, Array[Byte]] = Map()) {
  lazy val stringParams = stringSeqParams mapValues (_.head)
}

