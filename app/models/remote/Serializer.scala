package models.remote

import
  play.api.libs.json._,
    Json.toJson

import
  org.nlogo.{ api, mirror, shape },
    api.AgentVariables,
    api.ShapeList,
    api.Shape,
    shape._,
    mirror._

import scala.collection.JavaConversions._

object Serializer {

  def serialize(update: Update) : String = {

    import Mirrorables.{ Patch, Turtle, World, MirrorableWorld}

    val birthsMap  = update.births  groupBy (_.agent.kind) mapValues (births  => births  map serializeBirth)
    val changesMap = update.changes groupBy (_._1.kind)    mapValues (changes => changes map serializeAgentUpdate)
    val deathsMap  = update.deaths  groupBy (_.agent.kind) mapValues (deaths  => deaths  map serializeDeath)

    val updateMaps   = Seq(birthsMap, changesMap, deathsMap)
    val keyToKindMap = Map("turtles" -> Turtle, "patches" -> Patch, "world" -> World)

    val keyToJsObjectMap = keyToKindMap mapValues {
      kind =>
        val xss = updateMaps map (_.getOrElse(kind, Seq()))
        xss.foldLeft(JsObject(Seq())){ case (acc, xs) => acc ++ JsObject(xs) }
    }

    Json.stringify(JsObject(keyToJsObjectMap.toSeq))

  }

  def serializeBirth(birth: Birth) : (String, JsValue) = birth match {
    case Birth(AgentKey(kind, id), values) =>
      val varNames = getImplicitVariables(kind)
      import Mirrorables.World
      id.toString -> serializeAgentVariables(values, varNames)
  }

  def serializeAgentUpdate(update: (AgentKey, Seq[Change])) : (String, JsValue) = update match {
    case (AgentKey(kind, id), changes) =>
      val varNames       = getImplicitVariables(kind)
      val serializedVars = changes map {
        case Change(variable, value) =>
          val name = if (varNames.length > variable) varNames(variable) else variable.toString
          name -> serializeValue(value)
      }
      id.toString -> JsObject(serializedVars)
  }

  def serializeDeath(death: Death) : (String, JsValue) = death.agent.id.toString -> JsNull

  def serializeAgentVariables(values: Seq[AnyRef], varNames: Seq[String]) : JsObject =
    JsObject(varNames.zip(values map serializeValue))

  def getImplicitVariables(kind: Kind) : Seq[String] = {
    import Mirrorables.{ Link, Patch, Turtle, World, MirrorableWorld }
    import MirrorableWorld.WorldVar
    kind match {
      case Turtle => AgentVariables.getImplicitTurtleVariables(false)
      case Patch  => AgentVariables.getImplicitPatchVariables(false)
      case Link   => AgentVariables.getImplicitLinkVariables
      case World => 0 until WorldVar.maxId map (WorldVar.apply(_).toString)
      case _      => play.api.Logger.warn("Don't know how to get implicit vars for " + kind.toString); Seq()
    }
  }

  def serializeValue(value: AnyRef): JsValue = value match {
    case d: java.lang.Double  => JsNumber(d.doubleValue)
    case i: java.lang.Integer => JsNumber(i.intValue)
    case b: java.lang.Boolean => JsBoolean(b.booleanValue)
    case s: ShapeList         => JsObject(s.getShapes map serializeShape)
    case x                    => toJson(x.toString)
  }

  def serializeShape(shape: Shape) = {
    val shapeData = shape match {
      case vecShape: VectorShape => JsObject(Seq(
          "rotate"   -> JsBoolean(vecShape.isRotatable),
          "elements" -> toJson(vecShape.getElements map serializeElement)
        ))
      case linkShape: LinkShape  => toJson("")
    }
    shape.getName -> shapeData
  }

  def serializeElement(elt: Element) = {
    val shapeTypeData: JsObject = elt match {
      case p: Polygon => JsObject(Seq(
          "type"   -> toJson("polygon"),
          "xcors"  -> toJson(p.getXcoords map (x => JsNumber(x.intValue))),
          "ycors"  -> toJson(p.getYcoords map (x => JsNumber(x.intValue)))
        ))
      case r: Rectangle => JsObject(Seq(
          "type" -> toJson("rectangle"),
          "xmin" -> JsNumber(r.getX()),
          "ymin" -> JsNumber(r.getY()),
          "xmax" -> JsNumber(r.getX() + r.getWidth()),
          "ymax" -> JsNumber(r.getY() + r.getHeight())
        ))
      case c: Circle => JsObject(Seq(
          "type" -> toJson("circle"),
          "x"    -> JsNumber(c.getBounds().getX()),
          "y"    -> JsNumber(c.getBounds().getY()),
          "diam" -> JsNumber(c.getBounds().getWidth())
        ))
      case x =>  JsObject(Seq(
          "type" -> toJson(x.toString)
        ))
    }
    shapeTypeData ++ JsObject(Seq(
      "color"  -> serializeColor(elt.getColor),
      "filled" -> JsBoolean(elt.filled),
      "marked" -> JsBoolean(elt.marked)
    ))
  }

  def serializeColor(c: java.awt.Color) =
    toJson("rgba(" + c.getRed + ", " + c.getGreen + ", " + c.getBlue + ", " + c.getAlpha / 255.0 + ")")
}
