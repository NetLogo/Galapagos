package models.json

import
  org.nlogo.{ api, shape },
    api.Shape,
    shape.{ LinkShape, VectorShape }

import
  play.api.libs.json.{ JsBoolean, JsObject, Json }

sealed trait ShapeConverter[T <: Shape] extends JsonConverter[T]

object ShapeToJsonConverters {

  implicit def shape2Json(shape: Shape): JsonWritable =
    shape match {
      case vs: VectorShape => new VectorShapeConverter(vs)
      case ls: LinkShape   => new LinkShapeConverter(ls)
    }

  class VectorShapeConverter(override protected val target: VectorShape) extends ShapeConverter[VectorShape] {
    import scala.collection.JavaConverters._
    import models.json.ElemToJsonConverters.elem2Json
    override protected val extraProps = JsObject(Seq(
      "rotate"   -> JsBoolean(target.isRotatable),
      "elements" -> Json.toJson(target.getElements.asScala map (_.toJsonObj))
    ))
  }

  class LinkShapeConverter(override protected val target: LinkShape) extends ShapeConverter[LinkShape] {
    override protected val extraProps = JsObject(Seq())
  }

}
