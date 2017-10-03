// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models.compile

import
  org.nlogo.{ core, tortoise },
    core.{ CompilerException, model },
      model.ModelReader,
    tortoise.compiler.{ CompiledModel, CompiledWidget },
      CompiledModel.CompileResult

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
      modelResult map       (_.compiledCode),
      modelResult map       (_.model.info)                                       getOrElse FailureMessage,
      modelResult map       (_.model.code)                                       getOrElse FailureMessage,
      modelResult map       (m => m.widgets)                                     getOrElse Seq(),
      commands    mapValues (s => modelResult     map (_.compileCommand (s))     getOrElse FailureExceptionNel),
      reporters   mapValues (s => modelResult     map (_.compileReporter(s))     getOrElse FailureExceptionNel))

  def exportNlogo(modelResult: CompileResult[CompiledModel]): CompileResult[String] =
    modelResult.map(cm => ModelReader.formatModel(cm.model))

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
  override def mapValues[U](f: (T) => U): IDedValues[U] = IDedValuesMap(map.mapValues(f))
}

case class IDedValuesSeq[T](seq: Seq[T]) extends IDedValues[T] {
  override def mapValues[U](f: (T) => U): IDedValues[U] = IDedValuesSeq(seq.map(f))
}
