package models

import play.api.libs.json._, Json.toJson
import org.nlogo.mirror._
import org.nlogo.api.AgentKind
import org.nlogo.api.AgentVariables

object Serializer {
  def serialize(update: Update): String = {
    val turtles = toJson(update.births
      .filter(_.agent.kind == Mirrorables.Turtle).map(serializeBirth).toMap)
    val patches = toJson(update.births
      .filter(_.agent.kind == Mirrorables.Patch).map(serializeBirth).toMap)
    for (death <- update.deaths) {
      println(death.toString)
    }
    for (change <- update.changes) {
      println(change.toString)
    }
    Json.stringify(JsObject(
      "turtles" -> turtles ::
      "patches" -> patches ::
      List()
    ))
  }


  def serializeBirth(birth: Birth): (String, JsValue) = birth match {
    case Birth(AgentKey(Mirrorables.Turtle, id), values) => {
      val turtleVarNames = AgentVariables.getImplicitTurtleVariables(false)
      id.toString -> serializeAgentVariables(values, turtleVarNames)
    }
    case Birth(AgentKey(Mirrorables.Patch, id), values) => {
      val patchVarNames = AgentVariables.getImplicitPatchVariables(false)
      id.toString -> serializeAgentVariables(values, patchVarNames)
    }
    case other => {
      println("Unrecognized: " + other.toString)
      ("-1", JsNull)
    }
  }

  def serializeAgentVariables(values: Seq[AnyRef], varNames: Seq[String]): JsObject =
    JsObject(varNames.zip(values.map {
      case i: java.lang.Double => JsNumber(i.doubleValue)
      case b: java.lang.Boolean => JsBoolean(b.booleanValue)
      case x => toJson(x.toString)
    }))
}
