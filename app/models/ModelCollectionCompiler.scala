// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import
  java.io.File

import
  akka.actor.{ Actor, ActorRef }

import
  org.nlogo.tortoise.compiler.CompiledModel

import
  models.Util.usingSource

class ModelCollectionCompiler(getModels: () => Seq[File], cacher: ActorRef) extends Actor {

  import models.ModelCollectionCompiler.{ CheckBuiltInModels, compileModel }
  import models.StatusCacher.AllBuiltInModels

  override def receive: Receive = {
    case CheckBuiltInModels =>
      val allModels = getModels()
      cacher ! AllBuiltInModels(allModels)
      allModels.map { // `map` before parallelizing, so we don't thrash the hard disk by reading files in parallel --JAB (11/11/14)
        file => (file, usingSource(_.fromFile(file))(_.mkString))
      }.par.foreach {
        case (file, contents) => cacher ! compileModel(file, contents)
      }
  }

}

object ModelCollectionCompiler {
  case object CheckBuiltInModels
  protected[models] def compileModel(file: File, contents: String): ModelCompilationStatus =
    CompiledModel.fromNlogoContents(contents).map(ModelSaver(_)).fold(
      nel => CompilationFailure(file, nel.list.toList),
      _   => CompilationSuccess(file)
    )
}

sealed trait ModelCompilationStatus { def file: File }
case class CompilationSuccess(override val file: File)                             extends ModelCompilationStatus
case class CompilationFailure(override val file: File, exceptions: Seq[Exception]) extends ModelCompilationStatus
