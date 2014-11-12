package models.remote

import
  java.io.File

import
  scala.io.Source

import
  scalaz.Validation.FlatMap.ValidationFlatMapRequested

import
  akka.actor.{ Actor, ActorRef }

import
  org.nlogo.tortoise.CompiledModel

import
  models.{ ModelSaver, NetLogoModelCollection }

class ModelCollectionCompiler(modelsCollection: NetLogoModelCollection, cacher: ActorRef) extends Actor {
  import ModelCollectionCompiler.{ CheckBuiltInModels, compileModel }
  import StatusCacher.AllBuiltInModels
  override def receive: Receive = {
    case CheckBuiltInModels =>
      val allModels = modelsCollection.allModels.toSeq
      cacher ! AllBuiltInModels(allModels)
      allModels.map { // `map` before parallelizing, so we don't thrash the hard disk by reading files in parallel --JAB (11/11/14)
        file => (file, Source.fromFile(file).mkString)
      }.par.foreach {
        case (file, contents) => cacher ! compileModel(file, contents)
      }
  }
}

object ModelCollectionCompiler {
  case object CheckBuiltInModels
  protected[models] def compileModel(file: File, contents: String): ModelCompilationStatus =
    CompiledModel.fromNlogoContents(contents).flatMap(ModelSaver.validateWidgets).fold(
      nel => CompilationFailure(file, nel.list),
      _   => CompilationSuccess(file)
    )
}

sealed trait ModelCompilationStatus { def file: File }
case class CompilationSuccess(override val file: File)                             extends ModelCompilationStatus
case class CompilationFailure(override val file: File, exceptions: Seq[Exception]) extends ModelCompilationStatus
