// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

import
  javax.inject.{ Inject, Singleton }

import
  scala.concurrent.{ duration, ExecutionContext },
    duration.DurationInt,
    ExecutionContext.Implicits.global

import
  play.api.{ cache, Environment, Mode },
    cache.{ NamedCache, SyncCacheApi }

import
  akka.actor.{ ActorSystem, Props }

import
  com.google.inject.AbstractModule

import
  models.{ ModelCollectionCompiler, ModelsLibrary, StatusCacher },
    ModelCollectionCompiler.CheckBuiltInModels

@Singleton
class Startup @Inject() (actorSystem: ActorSystem, @NamedCache("compilation-statuses") cache: SyncCacheApi, environment: Environment) {
  val statusCacher       = actorSystem.actorOf(Props(classOf[StatusCacher], cache))
  val backgroundCompiler = actorSystem.actorOf(Props(classOf[ModelCollectionCompiler], () => ModelsLibrary.allModels(using environment.mode), statusCacher))
  if (environment.mode == Mode.Prod)
    actorSystem.scheduler.scheduleWithFixedDelay(0.seconds, 30.minutes)(new Runnable { def run: Unit = backgroundCompiler ! CheckBuiltInModels })
}

class StartupModule extends AbstractModule {
  override def configure(): Unit = {
    bind(classOf[Startup]).asEagerSingleton
  }
}
