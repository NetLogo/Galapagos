package controllers

import play.api._
import play.api.mvc._
import models.WebWorkspace
import org.nlogo.headless.HeadlessWorkspace

object Application extends Controller {

  private val modelsURL = "http://localhost:9001/assets/models/"
  private val modelName = "Wolf Sheep Predation"
  private val ws = workspace(modelsURL + java.net.URLEncoder.encode(modelName, "UTF-8") + ".nlogo")

  def index = Action {
    Ok(views.html.index("Your new application is ready."))
  }

  def netlogoCommand = Action {
    implicit request =>
      val bod = request.body.asFormUrlEncoded
      bod map (paramMap => Ok(ws.execute(paramMap("agentType").head, paramMap("cmd").head))) getOrElse (NotAcceptable)
  }

  private def workspace(url: String) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(io.Source.fromURL(url).mkString)
    wspace
  }
  
}
