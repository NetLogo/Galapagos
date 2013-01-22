package models

import play.api.libs.json._, Json.toJson
import org.nlogo.mirror._
import org.nlogo.api.AgentVariables

object Serializer {
  def serialize(update: Update): String = {
    val turtleBirths = JsObject(update.births
      .filter(_.agent.kind == Mirrorables.Turtle).map(serializeBirth))
    val patchBirths = JsObject(update.births
      .filter(_.agent.kind == Mirrorables.Patch).map(serializeBirth))
    val turtleChanges = JsObject(update.changes
      .filter(_._1.kind == Mirrorables.Turtle).map(serializeAgentUpdate))
    val patchChanges = JsObject(update.changes
      .filter(_._1.kind == Mirrorables.Patch).map(serializeAgentUpdate))
    val turtleDeaths = JsObject(update.deaths
      .filter(_.agent.kind == Mirrorables.Turtle).map(serializeDeath))

    Json.stringify(JsObject(Seq(
      "turtles" -> (turtleBirths ++ turtleChanges ++ turtleDeaths),
      "patches" -> (patchBirths ++ patchChanges)
    )))
  }

  def serializeBirth(birth: Birth): (String, JsValue) = birth match {
    case Birth(AgentKey(kind, id), values) =>
      val varNames = getImplicitVariables(kind)
      id.toString -> serializeAgentVariables(values, varNames)
  }

  def serializeAgentUpdate(update: (AgentKey, Seq[Change])): (String, JsObject) = update match {
    case (AgentKey(kind, id), changes) =>
      val varNames = getImplicitVariables(kind)
      val serializedVars = JsObject(changes.map{
        case Change(variable, value) =>
          (if (varNames.length > variable) varNames(variable)
           else variable.toString) -> serializeValue(value)
      })
      id.toString -> serializedVars
  }

  def serializeDeath(death: Death) = death.agent.id.toString -> JsNull

  def serializeAgentVariables(values: Seq[AnyRef], varNames: Seq[String]): JsObject =
    JsObject(varNames.zip(values.map{
      case i: java.lang.Double => JsNumber(i.doubleValue)
      case b: java.lang.Boolean => JsBoolean(b.booleanValue)
      case x => toJson(x.toString)
    }))

  def getImplicitVariables(kind: Kind): Seq[String] = kind match {
    case Mirrorables.Turtle =>
      AgentVariables.getImplicitTurtleVariables(false)
    case Mirrorables.Patch =>
      AgentVariables.getImplicitPatchVariables(false)
    case Mirrorables.Link =>
      AgentVariables.getImplicitLinkVariables
    case _ =>
      println("Don't know how to get implicit vars for " + kind.toString)
      Seq()
  }

  def serializeValue(value: AnyRef) = value match {
    case d: java.lang.Double => JsNumber(d.doubleValue)
    case b: java.lang.Boolean => JsBoolean(b.booleanValue)
    case x => toJson(x.toString)
  }

}
