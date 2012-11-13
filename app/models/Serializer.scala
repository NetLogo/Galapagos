package models

import play.api.libs.json._, Json.toJson
import org.nlogo.mirror._
import org.nlogo.api.AgentKind
import org.nlogo.api.AgentVariables

object Serializer {
  def serialize(update: Update): String = {
    println("Births")
    for (birth <- update.births) {
      println(serializeBirth(birth))
    }
    println("Deaths")
    for (death <- update.deaths) {
      println(death.toString)
    }
    println("Changes")
    for (change <- update.changes) {
      println(change.toString)
    }
    "hi"
  }


  def serializeBirth(birth: Birth): (JsValue, JsValue) = birth match {
    case Birth(AgentKey(Mirrorables.Turtle, id), values) => {
      val turtleVarNames = AgentVariables.getImplicitTurtleVariables(false)
      JsNumber(id) -> serializeAgentVariables(values, turtleVarNames)
    }
    case Birth(AgentKey(Mirrorables.Patch, id), values) => {
      val patchVarNames = AgentVariables.getImplicitPatchVariables(false)
      JsNumber(id) -> serializeAgentVariables(values, patchVarNames)
    }
    case other => {
      println(other.toString)
      (JsNumber(-1), JsNull)
    }
  }

  def serializeAgentVariables(values: Seq[AnyRef], varNames: Seq[String]): JsValue =
    toJson(varNames.zip(values.map {
      case i: java.lang.Double => JsNumber(i.doubleValue)
      case b: java.lang.Boolean => JsBoolean(b.booleanValue)
      case x => toJson(x.toString)
    }).toMap)
}
