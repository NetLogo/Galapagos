import akka.actor.Props

import
  play.api.{ libs, GlobalSettings, Application },
    libs.concurrent.Akka

import
  scala.concurrent.{ duration, ExecutionContext },
    duration.DurationInt,
    ExecutionContext.Implicits.global

import
  models.core.ModelsLibrary,
  models.local.{ ModelCollectionCompiler, StatusCacher },
    ModelCollectionCompiler.CheckBuiltInModels

object Global extends GlobalSettings {
  override def onStart(app: Application): Unit = {
    val actorSystem        = Akka.system(app)
    val statusCacher       = actorSystem.actorOf(Props(classOf[StatusCacher], app))
    val backgroundCompiler = actorSystem.actorOf(Props(classOf[ModelCollectionCompiler], ModelsLibrary, statusCacher))
    actorSystem.scheduler.schedule(0.seconds, 30.minutes)(backgroundCompiler ! CheckBuiltInModels)
    super.onStart(app)
  }
}
