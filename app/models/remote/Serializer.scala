package models.remote

import
  play.api.libs.json._,
    Json.toJson

import
  org.nlogo.{ api, mirror },
    api.AgentVariables,
    mirror._

object Serializer {

  def serialize(update: Update) : String = {

    import Mirrorables.{ Patch, Turtle }

    val birthsMap  = update.births  groupBy (_.agent.kind) mapValues (births  => births  map serializeBirth)
    val changesMap = update.changes groupBy (_._1.kind)    mapValues (changes => changes map serializeAgentUpdate)
    val deathsMap  = update.deaths  groupBy (_.agent.kind) mapValues (deaths  => deaths  map serializeDeath)

    val updateMaps   = Seq(birthsMap, changesMap, deathsMap)
    val keyToKindMap = Map("turtles" -> Turtle, "patches" -> Patch)

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
    JsObject(varNames.zip(values.map{
      case d: java.lang.Double  => JsNumber(d.doubleValue)
      case b: java.lang.Boolean => JsBoolean(b.booleanValue)
      case x                    => toJson(x.toString)
    }))

  def getImplicitVariables(kind: Kind) : Seq[String] = {
    import Mirrorables.{ Link, Patch, Turtle }
    kind match {
      case Turtle => AgentVariables.getImplicitTurtleVariables(false)
      case Patch  => AgentVariables.getImplicitPatchVariables(false)
      case Link   => AgentVariables.getImplicitLinkVariables
      case _      => play.api.Logger.warn("Don't know how to get implicit vars for " + kind.toString); Seq()
    }
  }

  def serializeValue(value: AnyRef) = value match {
    case d: java.lang.Double  => JsNumber(d.doubleValue)
    case b: java.lang.Boolean => JsBoolean(b.booleanValue)
    case x                    => toJson(x.toString)
  }

}
