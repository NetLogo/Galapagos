// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models.json

import
  org.nlogo.tortoise.compiler.json.TortoiseJson,
    TortoiseJson.{
      fields,
      JsArray  => TortoiseArray,
      JsBool   => TortoiseBool,
      JsDouble => TortoiseDouble,
      JsInt    => TortoiseInt,
      JsNull   => TortoiseNull,
      JsObject => TortoiseObject,
      JsString => TortoiseString }

import play.api.libs.json.{ JsArray, JsBoolean, JsNull, JsNumber, JsObject, JsString, JsValue }

object JsonConverter {
  def toTortoise(playJson: JsValue): TortoiseJson = {
    playJson match {
      case JsObject(elems)             => TortoiseObject(fields(elems.view.mapValues(toTortoise).toSeq*))
      case JsArray(elems)              => TortoiseArray(elems.map(toTortoise).toSeq)
      case JsNumber(n) if n.isValidInt => TortoiseInt(n.toInt)
      case JsNumber(n)                 => TortoiseDouble(n.toDouble)
      case JsString(s)                 => TortoiseString(s)
      case JsNull                      => TortoiseNull
      case JsBoolean(b)                => TortoiseBool(b)
      case _                           =>
        throw new Exception(s"Unexpected Play JSON type returned: $playJson")
    }
  }
}
