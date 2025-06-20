// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models.compile

import org.nlogo.core.CompilerException
import org.nlogo.tortoise.compiler.{ CompiledModel, CompiledWidget }
import org.nlogo.tortoise.compiler.CompiledModel.CompileResult
import org.nlogo.tortoise.compiler.xml.TortoiseModelLoader

import
  CompileResponse.Statements

case class CompileResponse(model:     CompileResult[String],
                           info:      String,
                           code:      String,
                           widgets:   Seq[CompiledWidget],
                           commands:  Statements,
                           reporters: Statements)

object CompileResponse {

  import scalaz.Scalaz.ToValidationOps

  type Statements = IDedValues[CompileResult[String]]

  def fromModel(modelResult: CompileResult[CompiledModel],
                commands:    IDedValues[String],
                reporters:   IDedValues[String]): CompileResponse =
    CompileResponse(
      modelResult.map(_.compiledCode),
      modelResult.map(_.model.info  ).getOrElse(FailureMessage),
      modelResult.map(_.model.code  ).getOrElse(FailureMessage),
      modelResult.map(m => m.widgets).getOrElse(Seq()),
      commands.mapValues( s => modelResult.map(_.compileCommand(s) ).getOrElse(FailureExceptionNel)),
      reporters.mapValues(s => modelResult.map(_.compileReporter(s)).getOrElse(FailureExceptionNel))
    )

  def exportNlogoXML(modelResult: CompileResult[CompiledModel]): CompileResult[String] =
    modelResult.map(cm => TortoiseModelLoader.write(cm.model))

  private val FailureMessage      = "Model failed to compile"
  private val FailureExceptionNel = new CompilerException(FailureMessage, 0, 0, "").failureNel[String]

}

// We allow users to pass in commands and reporters as either arrays or maps.
// Either way, we preserve keys/ordering with the responses. We can't just do
// the responses as maps with integer keys as you'd lose commands.length on
// the javascript side.
// BCH 11/11/2014
sealed trait IDedValues[T] {
  def mapValues[U](f: (T) => U): IDedValues[U]
}

case class IDedValuesMap[T](map: Map[String, T]) extends IDedValues[T] {
  override def mapValues[U](f: (T) => U): IDedValues[U] = IDedValuesMap(map.view.mapValues(f).toMap)
}

case class IDedValuesSeq[T](seq: Seq[T]) extends IDedValues[T] {
  override def mapValues[U](f: (T) => U): IDedValues[U] = IDedValuesSeq(seq.map(f))
}
