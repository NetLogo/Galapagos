package models.json

import
  java.awt.Color

import
  org.nlogo.shape.{ Circle, Element, Line, Polygon, Rectangle }

import
  play.api.libs.json.{ JsBoolean, JsNumber, JsObject, Json, JsString, JsValue }

sealed trait ElemConverter[T <: Element] extends JsonConverter[T] {

  protected def typ: String = target.toString

  final override protected def baseProps: JsObject =
    JsObject(Seq(
      "type"   -> JsString(typ),
      "color"  -> serializeColor(target.getColor),
      "filled" -> JsBoolean(target.filled),
      "marked" -> JsBoolean(target.marked)
    ))

  private def serializeColor(c: Color): JsValue = {
    val (r, g, b, a) = (c.getRed, c.getGreen, c.getBlue, c.getAlpha / 255.0)
    Json.toJson(s"rgba($r, $g, $b, $a)")
  }

}

object ElemToJsonConverters {

  implicit def elem2Json(target: Element): JsonWritable =
    target match {
      case p: Polygon   => new PolygonConverter(p)
      case r: Rectangle => new RectangleConverter(r)
      case c: Circle    => new CircleConverter(c)
      case l: Line      => new LineConverter(l)
      case e            => new OtherConverter(e)
    }

  class PolygonConverter(override protected val target: Polygon) extends ElemConverter[Polygon] {
    import scala.collection.JavaConverters._
    override protected val typ        = "polygon"
    override protected val extraProps = JsObject(Seq(
      "xcors" -> Json.toJson(target.getXcoords.asScala map (x => JsNumber(x.intValue))),
      "ycors" -> Json.toJson(target.getYcoords.asScala map (x => JsNumber(x.intValue)))
    ))
  }

  class RectangleConverter(override protected val target: Rectangle) extends ElemConverter[Rectangle] {
    override protected val typ        = "rectangle"
    override protected val extraProps = JsObject(Seq(
      "xmin" -> JsNumber(target.getX),
      "ymin" -> JsNumber(target.getY),
      "xmax" -> JsNumber(target.getX + target.getWidth),
      "ymax" -> JsNumber(target.getY + target.getHeight)
    ))
  }

  class CircleConverter(override protected val target: Circle) extends ElemConverter[Circle] {
    override protected val typ        = "circle"
    override protected val extraProps = JsObject(Seq(
      "x"    -> JsNumber(target.getBounds.getX),
      "y"    -> JsNumber(target.getBounds.getY),
      "diam" -> JsNumber(target.getBounds.getWidth)
    ))
  }

  class LineConverter(override protected val target: Line) extends ElemConverter[Line] {
    override protected val typ        = "line"
    override protected val extraProps = JsObject(Seq(
      "x1" -> JsNumber(target.getStart.getX),
      "y1" -> JsNumber(target.getStart.getY),
      "x2" -> JsNumber(target.getEnd.getX),
      "y2" -> JsNumber(target.getEnd.getY)
    ))
  }

  class OtherConverter(override protected val target: Element) extends ElemConverter[Element] {
    override protected val extraProps = JsObject(Seq())
  }

}
