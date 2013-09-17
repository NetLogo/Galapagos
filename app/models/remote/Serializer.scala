package models.remote

import
  play.api.libs.json.{ JsBoolean, JsNull, JsNumber, JsObject, Json, JsString, JsValue }

import
  org.nlogo.{ api, mirror, shape },
    api.{ AgentVariables, ShapeList, LogoList },
    mirror.{ AgentKey, Birth, Change, Death, Kind, Mirrorables, Update }

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

  private def serializeBirth(birth: Birth) : (String, JsValue) = {
    val Birth(AgentKey(kind, id), values) = birth
    val varNames = getVariableNamesForKind(kind)
    id.toString -> serializeAgentVariables(varNames, values)
  }

  private def serializeAgentUpdate(update: (AgentKey, Seq[Change])) : (String, JsValue) = {
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

  private def serializeDeath(death: Death) : (String, JsValue) = death.agent.id.toString -> JsNull

  private def serializeAgentVariables(keys: Seq[String], values: Seq[AnyRef]) : JsObject = {
    val kvPairs = keys zip (values map serializeValue)
    JsObject(kvPairs)
  }

  private def getVariableNamesForKind(kind: Kind) : Seq[String] = {
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

  private def serializeValue(value: AnyRef): JsValue = {
    import scala.collection.JavaConverters._
    import models.json.ShapeToJsonConverters._
    value match {
      case d: java.lang.Double  => JsNumber(d.doubleValue)
      case i: java.lang.Integer => JsNumber(i.intValue)
      case b: java.lang.Boolean => JsBoolean(b.booleanValue)
      case s: ShapeList         => JsObject(s.getShapes.asScala map (shape => shape.getName -> shape.toJsonObj))
      case l: LogoList          => Json.toJson(l.toVector map (serializeValue _))
      case x                    => JsString(x.toString)
    }
  }

}
