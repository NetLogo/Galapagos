// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  scala.io.Codec

import
  play.api.mvc.{ AnyContent, Request }

import
  models.Util.usingSource

object PlayUtil {

  implicit class EnhancedRequest(request: Request[AnyContent]) {

    // If Play actually made a good-faith effort at parameter extraction,
    // I wouldn't have to go through this rubbish... --Jason B. (10/3/13)
    def extractBundle: ParamBundle =
      request.body.asMultipartFormData map {
        formData =>
          val fileKVs = formData.files map {
            formFile =>
              val file = formFile.ref.path.toFile
              val arr  =
                if (file.length > 20E6.toLong)
                  "UPLOADED FILE TOO LARGE".getBytes
                else
                  usingSource(_.fromFile(file)(using Codec.ISO8859))(_.map(_.toByte).toArray)
              (formFile.key, arr)
          }
          ParamBundle(formData.asFormUrlEncoded, fileKVs.toMap)
      } orElse {
        request.body.asFormUrlEncoded.flatMap( (b) => if (b.isEmpty) { None } else { Some(b) } ).map( i => ParamBundle(Map(i.toSeq*)) )
      } orElse {
        Option(request.queryString).map(ParamBundle(_))
      } getOrElse {
        ParamBundle(Map(), Map())
      }

  }

}

case class ParamBundle(stringSeqParams: Map[String, Seq[String]], byteParams: Map[String, Array[Byte]] = Map()) {
  lazy val stringParams = stringSeqParams.view.mapValues(_.head)
}
