// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

import
  javax.inject.{ Inject, Provider }

import
  play.api.{ Configuration, Environment, http, mvc => apimvc, OptionalSourceMapper, routing => apirouting},
      http.DefaultHttpErrorHandler,
      apimvc.{ Result, Results, RequestHeader },
        Results.Status,
      apirouting.Router

import scala.concurrent.Future

class ErrorHandler @Inject() (
  env:          Environment,
  config:       Configuration,
  sourceMapper: OptionalSourceMapper,
  router:       Provider[Router]
) extends DefaultHttpErrorHandler(env, config, sourceMapper, router) {

  private implicit val mode = env.mode

  override protected def onNotFound(request: RequestHeader, message: String): Future[Result] =
    Future.successful(
      Status(Results.NotFound.header.status)(views.html.mainTheme(views.html.notFound(), "NetLogo Web - Page Not Found"))
    )
}
