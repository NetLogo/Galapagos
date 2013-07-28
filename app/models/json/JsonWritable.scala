package models.json

import
  play.api.libs.json.JsObject

trait JsonWritable {
  def toJsonObj : JsObject
  def toJson = toJsonObj.toString
}

trait JsonConverter[T] extends JsonWritable {

  protected def target: T
  protected def extraProps: JsObject
  protected def baseProps : JsObject = JsObject(Seq())

  final override def toJsonObj : JsObject = extraProps ++ baseProps

}
