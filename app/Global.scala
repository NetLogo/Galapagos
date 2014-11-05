import akka.actor.Props

import play.api,
  api.{ libs, GlobalSettings, Application },
  libs.concurrent.Akka

import
  scala.concurrent,
    concurrent.duration._,
    concurrent.ExecutionContext.Implicits.global

import
  models.ModelsLibrary,
  models.remote.{ StatusCacher, ModelLibraryCompiler},
    ModelLibraryCompiler.{modelCollectionCompiler, recompileAll}

object Global extends GlobalSettings {
  override def onStart(app: Application): Unit = {
    implicit val actorSystem = Akka.system(app)
    val statusCacher = actorSystem.actorOf(Props(classOf[StatusCacher], app))
    val backgroundCompiler = modelCollectionCompiler(ModelsLibrary, statusCacher)
    actorSystem.scheduler.schedule(0.seconds, 30.minutes, backgroundCompiler, recompileAll)
    super.onStart(app)
  }
}
