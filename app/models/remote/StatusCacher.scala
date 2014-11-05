package models.remote

import
  akka.actor.Actor

import
  models.remote.ModelLibraryCompiler.Messages.{AllBuiltInModels, ModelCompilationSuccess, ModelCompilationFailure}

import
  play.api,
    api.cache.Cache,
    api.Application

class StatusCacher(implicit app: Application) extends Actor {
  override def receive: Receive = {
    case AllBuiltInModels(files) =>
      Cache.set(StatusCacher.AllBuiltInModelsCacheKey, files.map(_.getPath))
    case s@ModelCompilationSuccess(file) => Cache.set(file.getPath, s)
    case f@ModelCompilationFailure(file, error) => Cache.set(file.getPath, f)
  }
}

object StatusCacher {
  val AllBuiltInModelsCacheKey = "allModelCompilationStatuses"
}
