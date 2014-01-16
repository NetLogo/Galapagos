package models.local

import
  org.nlogo.{ api, compile, nvm, shape, tortoise, workspace, core },
    compile.front.FrontEnd,
    nvm.{ DefaultParserServices, FrontEndInterface },
      FrontEndInterface.{ NoProcedures, ProceduresMap },
    shape.{ LinkShape, VectorShape },
    tortoise.Compiler,
    tortoise.json.JSONSerializer

import
  play.api.Logger

trait Widget {
  def toJS(implicit program: api.Program, procedures: ProceduresMap): String
  def compileFunc(func: => String, elseCase: => String) =
    try
      func
    catch {
      case ex:Exception =>
        Logger.error(ex.getMessage())
        elseCase
    }
}

object Widget {
  implicit class SuperButton(val b: core.Button) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) = {
      val src = compileFunc(s"function() { ${Compiler.compileCommands(b.source, procedures, program)} }", "function() {}")
      s"""Widgets.addButton("${b.display}", ${b.left}, ${b.top}, ${b.right}, ${b.bottom}, $src, ${b.forever})"""
    }
  }

  implicit class SuperSlider(val s: core.Slider) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) = {
      val setter = compileFunc(
          "function(newVal) {" +
            Compiler.compileCommands(s"""set ${s.varName} "PLACEHOLDER" """, procedures, program)
              .replace("\"PLACEHOLDER\"", "newVal") +
            "}",
          "function() { }")
        def intOrFunc(str: String): String = {
          import scalaz.Scalaz.ToStringOpsFromString
          str.parseDouble.fold(_ => compileFunc(s"function() { return ${Compiler.compileReporter(str, procedures, program)} }", "function() { }"), _ => str)
        }

        val min = intOrFunc(s.min)
        val max = intOrFunc(s.max)
        val step = intOrFunc(s.step)
        s"""Widgets.addSlider("${s.display}", ${s.left}, ${s.top}, ${s.right}, ${s.bottom},""" +
          s"""${setter}, $min, $max, ${s.default}, $step)"""
    }
  }

  implicit class SuperSwitch(val s: core.Switch) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) = {
      val setter =
            compileFunc(
              "function(newVal) {" +
                Compiler.compileCommands(s"""set ${s.varName} "PLACEHOLDER" """, procedures, program).replace("\"PLACEHOLDER\"", "newVal") +
                "}",
              "function() { }")
      s"""Widgets.addSwitch("${s.display}", ${s.left}, ${s.top}, ${s.right}, ${s.bottom}, ${setter})"""
    }
  }

  implicit class SuperMonitor(val m: core.Monitor) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) = {
        val monitorCode =
            compileFunc(
              "function() { return " +
                Compiler.compileReporter(s"precision ( ${m.source} ) ${m.precision}", procedures, program) +
                "}",
              "function() { return \"ERROR\" }")
        "Widgets.addMonitor(\"" +
          (if (m.display == "NIL") m.source else m.display) +
          s"""", ${m.left}, ${m.top}, ${m.right}, ${m.bottom}, $monitorCode)"""
    }
  }

  implicit class SuperOutput(val m: core.Output) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) = "Widgets.addOutput()"
  }

  implicit class SuperView(val v: core.View) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) =
      s"Widgets.addView(${v.left}, ${v.top}, ${v.right}, ${v.bottom})"
  }

  implicit class SuperTextBox(val tb: core.TextBox) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) =
      s"""Widgets.addTextBox("${tb.display}", ${tb.left}, ${tb.top}, ${tb.right}, ${tb.bottom})"""
  }

  implicit class SuperPlot(val g: core.Plot) extends Widget {
    override def toJS(implicit program: api.Program, procedures: ProceduresMap) =
      s"""Widgets.addPlot("${g.display}", ${g.left}, ${g.top}, ${g.right}, ${g.bottom}, ${g.ymin}, ${g.ymax}, ${g.xmin}, ${g.xmax} )"""
  }
   
}
