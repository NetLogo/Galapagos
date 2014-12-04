package models.json
import
  org.nlogo.{ api, core, tortoise },
    api.LogoList,
    core.{ Widget, Button, Monitor, Output, Plot, Pen, Slider, Switch, TextBox, View, Chooser,
           Direction, Horizontal, Vertical, UpdateMode, InputBox, AgentKind, Chooseable,
           InputBoxType, Num, Str, StrReporter, StrCommand, Col }

import
  play.api.libs.json.{Json, Reads, JsSuccess, JsError, JsPath, JsString, JsNumber, JsBoolean, JsNull,
                      JsArray, JsResult, JsValue}

object WidgetReads {
  val literalReads: Reads[AnyRef] = Reads[AnyRef] {
    case JsString(s)     => JsSuccess(s)
    case JsNumber(x)     => JsSuccess(x.toDouble: java.lang.Double)
    case JsBoolean(b)    => JsSuccess(b: java.lang.Boolean)
    case JsArray(jsVals) => {
      val seqRes = jsVals.foldLeft(JsSuccess(Seq()): JsResult[Seq[AnyRef]]) {
        (seqRes, jsVal) => for {
          seq <- seqRes
          x   <- literalReads.reads(jsVal)
        } yield (seq :+ x);
      }
      seqRes.map(seq => LogoList.fromIterator(seq.iterator))
    }
    case JsNull          => JsSuccess("NIL")
    case json            => JsError("Invalid literal value: " + json)
  }

  implicit val stringReads = Reads[String] {
    case JsNull      => JsSuccess("NIL")
    case JsString(s) => JsSuccess(s)
    case json        => JsError("Invalid string value: " + json)
  }

  implicit val updateModeReads = Reads[UpdateMode] {
    _.as[String].toUpperCase match {
      case "CONTINUOUS" => JsSuccess(UpdateMode.Continuous)
      case "TICKBASED"  => JsSuccess(UpdateMode.TickBased)
      case json         => JsError("View update mode can only be 'Continuous' or 'TickBased' but was " + json)
    }
  }

  implicit val viewReads   = Json.reads[View]
  implicit val buttonReads = Json.reads[Button]

  implicit val directionReads = Reads[Direction] {
    _.as[String].toUpperCase match {
      case "HORIZONTAL" => JsSuccess(Horizontal)
      case "VERTICAL"   => JsSuccess(Vertical)
      case json         => JsError("Slider direction can only be 'Horizontal' or 'Vertical' but was " + json)
    }
  }
  implicit val sliderReads = Json.reads[Slider]
  implicit val switchReads = Json.reads[Switch]

  implicit val chooseableReads: Reads[Chooseable] = Reads[Chooseable] {
    json => literalReads.reads(json) map (Chooseable.apply _)
  }
  implicit val chooseablesReads = Reads.list[Chooseable]
  implicit val chooserReads = Json.reads[Chooser]

  implicit val inputBoxTypeReads = Reads[InputBoxType] {
    json => List(Num, Str, StrReporter, StrCommand, Col).find {
      _.name == json.as[String]
    }.map(x => JsSuccess(x)).getOrElse(JsError("Invalid input box type: " + json))
  }
  implicit val inputBoxReads = Reads[InputBox[AnyRef]] {
    json => for {
      boxtype <- inputBoxTypeReads.reads(json \ "boxtype")
      jsValue = (json \ "value")
      value   <- if (boxtype == Col) {
        // Although doubles are valid colors, color input boxes specifically return integers
        JsSuccess(jsValue.as[Int]: java.lang.Integer)
      } else {
        literalReads.reads(jsValue)
      }
    } yield InputBox(
      (json \ "left")     .as[Int],
      (json \ "top")      .as[Int],
      (json \ "right")    .as[Int],
      (json \ "bottom")   .as[Int],
      (json \ "varName")  .as[String],
      value,
      (json \ "multiline").as[Boolean],
      boxtype
    )
  }

  implicit val monitorReads = Json.reads[Monitor]

  implicit val penReads     = Json.reads[Pen]
  implicit val plotReads    = Json.reads[Plot]
  implicit val outputReads  = Json.reads[Output]
  implicit val textBoxReads = Json.reads[TextBox]

  implicit val widgetReads = Reads[Widget] {
    json => ((json \ "type").as[String] match {
      case "view"     => viewReads
      case "button"   => buttonReads
      case "slider"   => sliderReads
      case "switch"   => switchReads
      case "chooser"  => chooserReads
      case "inputBox" => inputBoxReads
      case "monitor"  => monitorReads
      case "plot"     => plotReads
      case "output"   => outputReads
      case "textBox"  => textBoxReads
    }).reads(json)
  }

  implicit val widgetsReads = Reads.list[Widget]
}
