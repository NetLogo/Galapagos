// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

import
  javax.inject,
    inject.{ Inject, Provider }

import
  scala.concurrent,
    concurrent.Future

import
  play.api,
    api.{ http, mvc, routing, Configuration, Environment, OptionalSourceMapper },
      http.DefaultHttpErrorHandler,
      mvc.{ RequestHeader, Result, Results },
        Results.NotFound,
      routing.Router

class ErrorHandler @Inject() (
    env: Environment,
    config: Configuration,
    sourceMapper: OptionalSourceMapper,
    router: Provider[Router]
    ) extends DefaultHttpErrorHandler(env, config, sourceMapper, router) {
  override def onNotFound(request: RequestHeader, message: String): Future[Result] =
    Future.successful(NotFound(views.html.pageNotFound()))
}
