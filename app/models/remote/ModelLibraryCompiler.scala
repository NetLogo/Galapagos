package models.remote

import
  org.nlogo.tortoise.CompiledModel

import
  akka.{ actor, routing },
    actor._,
    routing.{ Broadcast, SmallestMailboxPool }

import
  java.io.File

import
  scala.io.Source

import
  scalaz.Validation.FlatMap.ValidationFlatMapRequested

import
  models.NetLogoModelCollection,
  models.ModelSaver.validateWidgets

object ModelLibraryCompiler {
  object Messages {
    case object CheckBuiltInModels
    case class AllBuiltInModels(models: Seq[File])
    case class CompileModel(modelFile: File, modelSource: String)
    case class ModelCompilationSuccess(file: File)
    case class ModelCompilationFailure(file: File, exceptions: List[Exception])
  }

  import Messages._

  def modelCollectionCompiler(collection: NetLogoModelCollection, cacher: ActorRef)(implicit system: ActorSystem) =
    system.actorOf(Props(classOf[ModelCollectionCompiler], collection, cacher))

  def recompileAll = CheckBuiltInModels

  class ModelCollectionCompiler(modelsCollection: NetLogoModelCollection, cacher: ActorRef) extends Actor {
    override def receive: Actor.Receive = {
      case CheckBuiltInModels =>
        val compilerRouter = context.actorOf(SmallestMailboxPool(4).props(Props(classOf[ModelCompiler], cacher)))
        val allModels = modelsCollection.allModels.toSeq
        cacher ! AllBuiltInModels(allModels)
        allModels.foreach { modelFile =>
          val modelContents = Source.fromFile(modelFile).mkString
          compilerRouter ! CompileModel(modelFile, modelContents)
        }
        compilerRouter ! Broadcast(PoisonPill)
    }
  }

  class ModelCompiler(reporter: ActorRef) extends Actor {
    override def receive: Receive = {
      case CompileModel(modelFile, modelString) =>
        reporter ! CompiledModel.fromNlogoContents(modelString).flatMap(validateWidgets).fold(
          fail    => ModelCompilationFailure(modelFile, fail.list),
          success => ModelCompilationSuccess(modelFile)
        )
    }
  }
}
