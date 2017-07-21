// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package models

import
  java.io.File

import
  akka.actor.Actor

import
  play.api.cache.SyncCacheApi

class StatusCacher(cache: SyncCacheApi) extends Actor {
  import models.StatusCacher.{ AllBuiltInModels, AllBuiltInModelsCacheKey }
  override def receive: Receive = {
    case AllBuiltInModels(files)        => cache.set(AllBuiltInModelsCacheKey, files.map(_.getPath))
    case status: ModelCompilationStatus => cache.set(status.file.getPath, status)
  }
}

object StatusCacher {
  val AllBuiltInModelsCacheKey = "allModelCompilationStatuses"
  private[models] case class AllBuiltInModels(models: Seq[File])
}
