package models.local

import
  org.nlogo.{ core, tortoise },
    core.{ AgentKind, Button, Chooseable, ChooseableBoolean, ChooseableDouble, ChooseableList, ChooseableString,
           Chooser, Direction, Horizontal, InputBox, InputBoxType, Monitor, Output, Pen, Plot, Slider, Switch, TextBox,
           UpdateMode, Vertical, View, Widget },
    tortoise.CompiledModel,
      CompiledModel.CompileResult

import
  play.api.libs.json.{ Json, Writes, JsObject, JsValue, JsArray, JsNull, JsString, JsNumber },
    Json.toJsFieldJsValueWrapper

import
  models.json.CompileWrites._

object CompiledWidget {
  implicit val widgetWrites = Writes[CompiledWidget[Widget]](_.toJson)

  def compile[W <: Widget, T](model: CompiledModel)(widget: W): CompiledWidget[Widget] = {
    def compileCmd(code: String, agentType: String = "OBSERVER") =
      model.compileCommand(sanitizeSource(code), toKind(agentType))
    def compileRep(code: String) = model.compileReporter(sanitizeSource(code))
    def compilePen(pen: Pen)     = CompiledPen(pen, compileCmd(pen.setupCode), compileCmd(pen.updateCode))
    widget match {
      case v: View        => CompiledView(v)
      case b: Button      => CompiledButton(b, compileCmd(b.source, b.buttonType))
      case p: Plot        => CompiledPlot(p, compileCmd(p.setupCode), compileCmd(p.updateCode), p.pens map compilePen)
      case p: Pen         => compilePen(p)
      case t: TextBox     => CompiledTextBox(t)
      case s: Slider      => CompiledSlider(s, compileRep(s.min), compileRep(s.max), compileRep(s.step))
      case s: Switch      => CompiledSwitch(s)
      case m: Monitor     => CompiledMonitor(m, compileRep(s"${m.source}"))
      case c: Chooser     => CompiledChooser(c)
      case i: InputBox[T] => CompiledInputBox[T](i)
      case o: Output      => CompiledOutput(o)
    }
  }

  private def sanitizeSource(s: String) = s.replace("\\n", "\n").replace("\\\\", "\\").replace("\\\"", "\"")

  private def toKind(agentType: String): AgentKind =
    agentType.toUpperCase match {
      case "OBSERVER" => AgentKind.Observer
      case "TURTLE"   => AgentKind.Turtle
      case "PATCH"    => AgentKind.Patch
      case "LINK"     => AgentKind.Link
    }
}

sealed trait CompiledWidget[+W <: Widget] {
  def widget: W
  protected val widgetTypeEntry: (String, JsValue) = {
    val className = widget.getClass.getSimpleName
    "type" -> JsString(className.substring(0,1).toLowerCase ++ className.substring(1))
  }

  protected implicit val nilWrites = Writes[String] {
    case "NIL" => JsNull
    case s     => JsString(s)
  }

  def toJson = widgetJson + widgetTypeEntry ++ extraJson
  protected def widgetJson: JsObject
  protected def extraJson = Json.obj()
}

case class CompiledView(widget: View) extends CompiledWidget[View] {
  private implicit val updateModeWrites = Writes[UpdateMode](m => Json.toJson(m.toString))
  protected def widgetJson = Json.writes[View].writes(widget)
}

case class CompiledButton(widget: Button, compiledSource: CompileResult[String]) extends CompiledWidget[Button] {
  protected def widgetJson = Json.writes[Button].writes(widget)
  override protected def extraJson = Json.obj("compiledSource" -> compiledSource)
}

case class CompiledPlot(widget: Plot,
                        compiledSetupCode: CompileResult[String],
                        compiledUpdateCode: CompileResult[String],
                        compiledPens: List[CompiledPen]) extends CompiledWidget[Plot] {
  private implicit val pensWrites = Writes[List[Pen]](_ => JsArray(compiledPens map { _.toJson }))
  protected def widgetJson = Json.writes[Plot].writes(widget)
  override protected def extraJson = Json.obj(
    "compiledSetupCode"  -> compiledSetupCode,
    "compiledUpdateCode" -> compiledUpdateCode
  )
}

case class CompiledPen(widget: Pen,
                        compiledSetupCode: CompileResult[String],
                        compiledUpdateCode: CompileResult[String]) extends CompiledWidget[Pen] {
  protected def widgetJson = Json.writes[Pen].writes(widget)

  override protected def extraJson = Json.obj(
    "compiledSetupCode"  -> compiledSetupCode,
    "compiledUpdateCode" -> compiledUpdateCode
  )
}

case class CompiledTextBox(widget: TextBox) extends CompiledWidget[TextBox] {
  protected def widgetJson = Json.writes[TextBox].writes(widget)
}

case class CompiledChooser(widget: Chooser) extends CompiledWidget[Chooser] {
  private implicit def choicesWrites: Writes[List[Chooseable]] = Writes[List[Chooseable]](xs => JsArray(xs map {
    case ChooseableDouble(d)  => Json.toJson(d.doubleValue)
    case ChooseableString(s)  => Json.toJson(s)
    case ChooseableList(l)    => Json.toJson(l.toList.asInstanceOf[List[Chooseable]])
    case ChooseableBoolean(b) => Json.toJson(b.booleanValue)
  }))
  protected def widgetJson = Json.writes[Chooser].writes(widget)
}

case class CompiledSlider(widget:       Slider,
                          compiledMin:  CompileResult[String],
                          compiledMax:  CompileResult[String],
                          compiledStep: CompileResult[String]) extends CompiledWidget[Slider] {
  private implicit val directionWrites = Writes[Direction] {
    case Horizontal => Json.toJson("horizontal")
    case Vertical   => Json.toJson("vertical")
  }

  protected def widgetJson = Json.writes[Slider].writes(widget)
  override protected def extraJson = Json.obj(
    "compiledMin"  -> compiledMin,
    "compiledMax"  -> compiledMax,
    "compiledStep" -> compiledStep
  )
}

case class CompiledSwitch(widget: Switch) extends CompiledWidget[Switch] {
  protected def widgetJson = Json.writes[Switch].writes(widget)
}

case class CompiledMonitor(widget: Monitor, compiledSource: CompileResult[String]) extends CompiledWidget[Monitor] {
  override protected def extraJson = Json.obj(
    "compiledSource" -> compiledSource
  )
  protected def widgetJson = Json.writes[Monitor].writes(widget)
}

case class CompiledInputBox[T](widget: InputBox[T]) extends CompiledWidget[InputBox[T]] {
  private implicit val inputBoxTypeWrites = Writes[InputBoxType](t => Json.toJson(t.name))
  // The writes macro can't handle generics it seems, so have to do it by hand. BCH 9/20/2014
  protected def widgetJson = Json.obj(
    "left"      -> widget.left,
    "top"       -> widget.top,
    "right"     -> widget.right,
    "bottom"    -> widget.bottom,
    "varName"   -> widget.varName,
    "value"     -> (widget.value match {
        case d: Double => JsNumber(d)
        case s: String => JsString(s)
        case c: Int    => JsNumber(c) // color
      }),
    "multiline" -> widget.multiline,
    "boxtype"   -> widget.boxtype
  )
}

case class CompiledOutput(widget: Output) extends CompiledWidget[Output] {
  protected def widgetJson = Json.writes[Output].writes(widget)
}
