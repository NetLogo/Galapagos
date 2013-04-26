package models.remote

import
  java.awt.Color

import
  play.api.libs.json.{ JsBoolean, JsNull, JsNumber, JsObject, Json, JsString, JsValue },
    Json.toJson

import
  org.nlogo.{ api, mirror, shape },
    api.{ AgentVariables, Shape, ShapeList },
    mirror.{ AgentKey, Birth, Change, Death, Kind, Mirrorables, Update },
    shape.{ Circle, Element, Line, LinkShape, Polygon, Rectangle, VectorShape }

import scala.collection.JavaConversions._

object Serializer {

  def serialize(update: Update) : String = {

    import Mirrorables.{ Patch, Turtle, World, Link }

    val birthsMap  = update.births  groupBy (_.agent.kind) mapValues (births  => births  map serializeBirth)
    val changesMap = update.changes groupBy (_._1.kind)    mapValues (changes => changes map serializeAgentUpdate)
    val deathsMap  = update.deaths  groupBy (_.agent.kind) mapValues (deaths  => deaths  map serializeDeath)
    val updateMaps = Seq(birthsMap, changesMap, deathsMap)

    if (updateMaps.forall(_.isEmpty))
      ""
    else {
      val keyToKindMap = Map("turtles" -> Turtle, "patches" -> Patch, "world" -> World, "links" -> Link)
      val keyToJsObjectMap = keyToKindMap mapValues {
        kind =>
          val xss = updateMaps map (_.getOrElse(kind, Seq()))
          xss.foldLeft(JsObject(Seq())){ case (acc, xs) => acc ++ JsObject(xs) }
      }
      Json.stringify(JsObject(keyToJsObjectMap.toSeq))
    }

  }

  def serializeBirth(birth: Birth) : (String, JsValue) = {
    val Birth(AgentKey(kind, id), values) = birth
    val varNames = getVariableNamesForKind(kind)
    id.toString -> serializeAgentVariables(varNames, values)
  }

  def serializeAgentUpdate(update: (AgentKey, Seq[Change])) : (String, JsValue) = {
    val (AgentKey(kind, id), changes) = update
    val varNames = getVariableNamesForKind(kind)
    val serializedVars = changes map {
      case Change(variable, value) =>
        val name = {
          if (varNames.length > variable)
            varNames(variable)
          else
            variable.toString
        }
        name -> serializeValue(value)
    }
    id.toString -> JsObject(serializedVars)
  }

  def serializeDeath(death: Death) : (String, JsValue) = death.agent.id.toString -> JsNull

  def serializeAgentVariables(keys: Seq[String], values: Seq[AnyRef]) : JsObject = {
    val kvPairs = keys zip (values map serializeValue)
    JsObject(kvPairs)
  }

  def getVariableNamesForKind(kind: Kind) : Seq[String] = {
    import Mirrorables.{ Link, Patch, Turtle, World, MirrorableWorld }
    import MirrorableWorld.WorldVar
    kind match {
      case Turtle => AgentVariables.getImplicitTurtleVariables(false)
      case Patch  => AgentVariables.getImplicitPatchVariables(false)
      case Link   => AgentVariables.getImplicitLinkVariables
      case World  => 0 until WorldVar.maxId map (WorldVar.apply(_).toString)
      case _      => play.api.Logger.warn("Don't know how to get implicit vars for " + kind.toString); Seq()
    }
  }

  def serializeValue(value: AnyRef): JsValue = value match {
    case d: java.lang.Double  => JsNumber(d.doubleValue)
    case i: java.lang.Integer => JsNumber(i.intValue)
    case b: java.lang.Boolean => JsBoolean(b.booleanValue)
    case s: ShapeList         => JsObject(s.getShapes map serializeShape)
    case x                    => JsString(x.toString)
  }

  def serializeShape(shape: Shape) : (String, JsValue) = {
    val shapeData = shape match {
      case vecShape: VectorShape => JsObject(Seq(
          "rotate"   -> JsBoolean(vecShape.isRotatable),
          "elements" -> toJson(vecShape.getElements map serializeElement)
        ))
      case linkShape: LinkShape => JsString("")
    }
    shape.getName -> shapeData
  }

  def serializeElement(elem: Element) : JsObject = {
    val shapeTypeData = elem match {
      case p: Polygon => JsObject(Seq(
          "type"   -> JsString("polygon"),
          "xcors"  -> toJson(p.getXcoords map (x => JsNumber(x.intValue))),
          "ycors"  -> toJson(p.getYcoords map (x => JsNumber(x.intValue)))
        ))
      case r: Rectangle => JsObject(Seq(
          "type" -> JsString("rectangle"),
          "xmin" -> JsNumber(r.getX),
          "ymin" -> JsNumber(r.getY),
          "xmax" -> JsNumber(r.getX + r.getWidth),
          "ymax" -> JsNumber(r.getY + r.getHeight)
        ))
      case c: Circle => JsObject(Seq(
          "type" -> JsString("circle"),
          "x"    -> JsNumber(c.getBounds.getX),
          "y"    -> JsNumber(c.getBounds.getY),
          "diam" -> JsNumber(c.getBounds.getWidth)
        ))
      case l: Line => JsObject(Seq(
          "type" -> JsString("line"),
          "x1"   -> JsNumber(l.getStart.getX),
          "y1"   -> JsNumber(l.getStart.getY),
          "x2"   -> JsNumber(l.getEnd.getX),
          "y2"   -> JsNumber(l.getEnd.getY)
        ))
      case x =>  JsObject(Seq(
          "type" -> JsString(x.toString)
        ))
    }
    shapeTypeData ++ JsObject(Seq(
      "color"  -> serializeColor(elem.getColor),
      "filled" -> JsBoolean(elem.filled),
      "marked" -> JsBoolean(elem.marked)
    ))
  }

  def serializeColor(c: Color) = {
    val (r, g, b, a) = (c.getRed, c.getGreen, c.getBlue, c.getAlpha / 255.0)
    toJson(s"rgba($r, $g, $b. $a)")
  }

}
