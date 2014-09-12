package models.local

import
  scala.util.Try

import
  org.nlogo.{ api, core, nvm },
    api.Program,
    core.{ Button, Monitor, Output, Plot, Slider, Switch, TextBox, View, Chooser },
    nvm.FrontEndInterface.ProceduresMap

import
  play.api.Logger

sealed trait DoesCompilation {

  import org.nlogo.tortoise.Compiler

  protected def defaultJS: String

  protected def compile(compilerFunc: (Compiler.type) => String): String =
    try compilerFunc(Compiler)
    catch {
      case ex: Exception =>
        Logger.warn(ex.getMessage)
        defaultJS
    }

}

trait CompilesCommands extends DoesCompilation {
  override protected val defaultJS = ""
  protected def compileCommands(logo: String)(implicit oldProcedures: ProceduresMap, program: Program): String =
    compile(_.compileCommands(logo, oldProcedures, program))
}

trait CompilesReporters extends DoesCompilation {
  override protected val defaultJS = "\"ERROR\""
  protected def compileReporter(logo: String)(implicit oldProcedures: ProceduresMap, program: Program): String =
    compile(_.compileReporter(logo, oldProcedures, program))
}

trait WidgetJS {
  def toJS(implicit program: Program, procedures: ProceduresMap): String
  protected def sanitizeSource(s: String) = s.replace("\\n", "\n").replace("\\\\", "\\").replace("\\\"", "\"")
}

object WidgetJS {

  private val Placeholder = "\"PLACEHOLDER\""

  implicit class EnhancedButton(val b: Button) extends WidgetJS with CompilesCommands {
    override def toJS(implicit program: Program, procedures: ProceduresMap) = {
      val src = s"function() { ${compileCommands(sanitizeSource(b.source))} }"
      s"""Widgets.addButton("${b.display}", ${b.left}, ${b.top}, ${b.right}, ${b.bottom}, $src, ${b.forever})"""
    }
  }

  implicit class EnhancedSlider(val s: Slider) extends WidgetJS with CompilesCommands with CompilesReporters {
    override def toJS(implicit program: Program, procedures: ProceduresMap) = {

      def intOrFunc(str: String): String =
        Try(str.toDouble).map(_ => str).getOrElse(s"function() { return ${compileReporter(str)} }")

      val Seq(min, max, step) = Seq(s.min, s.max, s.step) map intOrFunc

      val varName    = "newVal"
      val setterCode = compileCommands(s"""set ${s.varName} $Placeholder """).replace(Placeholder, varName)
      val setter     = s"function($varName) { $setterCode }"

      s"""Widgets.addSlider("${s.display}", ${s.left}, ${s.top}, ${s.right}, ${s.bottom}, $setter, $min, $max, ${s.default}, $step)"""

    }
  }

  implicit class EnhancedSwitch(val s: Switch) extends WidgetJS with CompilesCommands {
    override def toJS(implicit program: Program, procedures: ProceduresMap) = {
      val varName    = "newVal"
      val setterCode = compileCommands(s"""set ${s.varName} $Placeholder """).replace(Placeholder, varName)
      val setter     = s"function($varName) { $setterCode }"
      s"""Widgets.addSwitch("${s.display}", ${s.left}, ${s.top}, ${s.right}, ${s.bottom}, $setter)"""
    }
  }

  implicit class EnhancedMonitor(val m: Monitor) extends WidgetJS with CompilesReporters {
    override def toJS(implicit program: Program, procedures: ProceduresMap) = {
      val reporterCode = compileReporter(s"precision ( ${sanitizeSource(m.source)} ) ${m.precision}")
      val monitorCode  = s"function() { return $reporterCode }"
      val displayValue = if (m.display == "NIL") m.source else m.display
      s"""Widgets.addMonitor("$displayValue", ${m.left}, ${m.top}, ${m.right}, ${m.bottom}, $monitorCode)"""
    }
  }

  implicit class EnhancedOutput(val m: Output) extends WidgetJS {
    override def toJS(implicit program: Program, procedures: ProceduresMap) =
      "Widgets.addOutput()"
  }

  implicit class EnhancedView(val v: View) extends WidgetJS {
    override def toJS(implicit program: Program, procedures: ProceduresMap) =
      s"Widgets.addView(${v.left}, ${v.top}, ${v.right}, ${v.bottom})"
  }

  implicit class EnhancedTextBox(val tb: TextBox) extends WidgetJS {
    override def toJS(implicit program: Program, procedures: ProceduresMap) =
      s"""Widgets.addTextBox("${tb.display}", ${tb.left}, ${tb.top}, ${tb.right}, ${tb.bottom})"""
  }

  implicit class EnhancedChooser(val c: Chooser) extends WidgetJS with CompilesCommands {
    override def toJS(implicit program: Program, procedures: ProceduresMap) = {
      val varName = "newVal"
      val setterCode = compileCommands(s"""set ${c.varName} $Placeholder""").replace(Placeholder, varName)
      val choices = "[\"" + c.choices.map(_.toString).mkString("\", \"") + "\"]"
      val setter = s"function($varName) { $setterCode }"
      s"""|Widgets.addChooser("${c.display}", ${c.left}, ${c.top}, ${c.right}, ${c.bottom},
          |                    "${c.default}", ${choices},
          |                    $setter);""".stripMargin
    }
  }


  implicit class EnhancedPlot(val g: Plot) extends WidgetJS {
    override def toJS(implicit program: Program, procedures: ProceduresMap) =
      s"""Widgets.addPlot("${g.display}", ${g.left}, ${g.top}, ${g.right}, ${g.bottom}, ${g.ymin}, ${g.ymax}, ${g.xmin}, ${g.xmax} )"""
  }
   
}
