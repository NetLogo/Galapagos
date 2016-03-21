// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  akka.stream.scaladsl.StreamConverters

import
  play.api.{ Environment, mvc },
    mvc.{ Result, Results }

private[controllers] trait ResourceSender {

  self: Results =>

  protected def replyWithResource(environment: Environment)
                                 (resourcePath: String)
                                 (contentType: String): Result = {
    val resourceOpt = environment.resourceAsStream(resourcePath)
    val okOpt =
      resourceOpt.map {
        stream =>
          val content = StreamConverters.fromInputStream(() => stream)
          Ok.chunked(content).as(contentType)
      }
    okOpt.getOrElse(NotFound)
  }

}
