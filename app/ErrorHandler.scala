import javax.inject._

import play.api.http.DefaultHttpErrorHandler
import play.api._
import play.api.mvc._
import play.api.mvc.Results._
import play.api.routing.Router
import scala.concurrent._

class ErrorHandler @Inject() (
    env: Environment,
    config: Configuration,
    sourceMapper: OptionalSourceMapper,
    router: Provider[Router]
    ) extends DefaultHttpErrorHandler(env, config, sourceMapper, router) {
  override def onNotFound(request: RequestHeader, message: String) =
    Future.successful(NotFound(views.html.pageNotFound()))
}