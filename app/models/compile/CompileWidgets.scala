// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models.compile

import
  models.json.JsonConverter

import
  org.nlogo.{ core, tortoise },
    core.Widget,
    tortoise.compiler.{ json => tortoisejson },
      tortoisejson.{ TortoiseJson, WidgetToJson },
        TortoiseJson.{ JsArray => TortoiseArray },
        WidgetToJson.readWidgetJson

import
  play.api.libs.json.Json

import
  scalaz.{ Scalaz, std, syntax, ValidationNel },
    Scalaz.ToValidationOps,
    syntax.traverse._,
    std.list._


object CompileWidgets {
  def apply(json: String): ValidationNel[String, List[Widget]] = {
    JsonConverter.toTortoise(Json.parse(json)) match {
      case TortoiseArray(widgets) => widgets.map(readWidgetJson).toList.sequenceU
      case other                  => s"$other (a ${other.getClass.getSimpleName}) is not a valid list of widgets".failureNel
    }
  }
}
