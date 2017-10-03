// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models.json

import
  org.nlogo.{ core, tortoise },
    core.CompilerException,
    tortoise.compiler.{ CompiledModel, CompiledWidget, WidgetCompiler },
      CompiledModel.CompileResult

import
  play.api.libs.json.{ Json, JsString, Writes }

import
  models.compile.{ CompileResponse, IDedValuesMap, IDedValuesSeq },
    CompileResponse.Statements

object Writers {

  implicit val compileResponseWrites: Writes[CompileResponse] =
    Writes(
      (response: CompileResponse) => Json.obj(
        "model"     -> response.model,
        "info"      -> response.info,
        "code"      -> response.code,
        "widgets"   -> response.widgets,
        "commands"  -> response.commands,
        "reporters" -> response.reporters
      )
    )

  implicit val compiledStmtsWrites: Writes[Statements] =
    Writes {
      (_: Statements) match {
        case IDedValuesMap(map) => Json.toJson(map)
        case IDedValuesSeq(seq) => Json.toJson(seq)
      }
    }

  implicit val compileResultWrites: Writes[CompileResult[String]] = Writes {
    (result: CompileResult[String]) => Json.obj(
      "success" -> result.isSuccess,
      "result"  -> result.fold(_.list.toList, JsString.apply)
    )
  }

  implicit val compilerExceptionWrites: Writes[CompilerException] = Writes {
    (ex: CompilerException) => Json.obj(
      "message" -> ex.getMessage,
      "start"   -> ex.start,
      "end"     -> ex.end
    )
  }

  implicit val compiledWidgetWrites: Writes[Seq[CompiledWidget]] = Writes {
    (widgets: Seq[CompiledWidget]) =>
      JsString(WidgetCompiler.formatWidgets(widgets))
  }

}
