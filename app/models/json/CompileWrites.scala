package models.json

import
  org.nlogo.{ core, tortoise },
    core.CompilerException,
    tortoise.CompiledModel.CompileResult

import
  play.api.libs.json.{ Json, JsString, Writes }

object CompileWrites {
  implicit val compileResultWrites: Writes[CompileResult[String]] = Writes {
    (result: CompileResult[String]) => Json.obj(
      "success" -> result.isSuccess,
      "result"  -> result.fold(_.list, JsString.apply)
    )
  }
  implicit val compilerExceptionWrites: Writes[CompilerException] = Writes {
    (ex: CompilerException) => Json.obj(
      "message" -> ex.getMessage,
      "start"   -> ex.start,
      "end"     -> ex.end
    )
  }
}
