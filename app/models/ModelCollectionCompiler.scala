// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import
  java.io.File

import
  akka.actor.{ Actor, ActorRef }

import
  org.nlogo.tortoise.compiler.{ CompiledModel, Compiler }

import
  models.Util.usingSource

import
  scala.collection.parallel.CollectionConverters._

class ModelCollectionCompiler(getModels: () => Seq[File], cacher: ActorRef) extends Actor {

  import models.ModelCollectionCompiler.{ CheckBuiltInModels, compileModel }
  import models.StatusCacher.AllBuiltInModels

  override def receive: Receive = {
    case CheckBuiltInModels =>
      val allModels = getModels()
      cacher ! AllBuiltInModels(allModels)
      // `map` before parallelizing, so we don't thrash the hard disk by reading
      // files in parallel --Jason B. (11/11/14)
      allModels.map {
        file => (file, usingSource(_.fromFile(file))(_.mkString))
      }.par.foreach {
        // A `Compiler` keeps imported extension prims in mutable state, so parallel compiles can't share one.  -Jeremy B October 2026
        case (file, contents) => cacher ! compileModel(new Compiler(), file, contents)
      }
  }

}

object ModelCollectionCompiler {
  case object CheckBuiltInModels
  protected[models] def compileModel(compiler: Compiler, file: File, contents: String): ModelCompilationStatus =
    CompiledModel.fromNlogoXMLContents(contents, compiler).map(ModelSaver(_)).fold(
      nel => CompilationFailure(file, nel.list.toList),
      _   => CompilationSuccess(file)
    )
}

sealed trait ModelCompilationStatus { def file: File }
case class CompilationSuccess(override val file: File)                             extends ModelCompilationStatus
case class CompilationFailure(override val file: File, exceptions: Seq[Exception]) extends ModelCompilationStatus
