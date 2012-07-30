package controllers

import play.api._
import play.api.mvc._
import libs.json.Json, Json.{ toJson, stringify }

import org.nlogo.headless.HeadlessWorkspace

import models.WebWorkspace


object Application extends Controller {

  private val modelsURL = "http://localhost:9001/assets/models/"
  private val modelName = "Wolf Sheep Predation"
  private val ws = workspace(modelsURL + java.net.URLEncoder.encode(modelName, "UTF-8") + ".nlogo")
  
  private val nameBuffer = collection.mutable.ArrayBuffer[String]()  //@ Baaaaaad

  def index       = Action {                     Ok(views.html.index("Your new application is ready.")) }
  def client      = Action { implicit request => Ok(views.html.client())                                }
  def clientError = Action {                     Ok(views.html.client_error())                          }

  def handleSocket() = WebSocket.async[libs.json.JsValue] {



  }
  
  def validateName = Action {

    implicit request =>
      
      def validName(name: String) : Boolean = {
        !(name.isEmpty || name.length() >= 13 || nameBuffer.contains(name) || name.matches(""".*[^ \w].*"""))
      }
      
      def makeJson(isValid: Boolean, body: String) : String = {
        stringify(toJson(Map("valid" -> toJson(isValid.toString), "body" -> toJson(body))))
      }

      val name = request.body.asFormUrlEncoded flatMap (_.get("username") map (_(0).trim.replaceAll(" +", " "))) getOrElse("")
      Ok(if (validName(name)) { nameBuffer append name; makeJson(true, name) } else makeJson(false, ""))
  
  }
  
  def netlogoCommand = Action {
    implicit request =>
      play.api.Logger.info("Hey!  Got in!  Here's the seq: " + nameBuffer.toString)
      val bod = request.body.asFormUrlEncoded
      bod map (paramMap => Ok(ws.execute(paramMap("agentType").head, paramMap("cmd").head))) getOrElse (NotAcceptable)
  }

  private def workspace(url: String) : WebWorkspace = {
    val wspace = HeadlessWorkspace.newInstance(classOf[WebWorkspace]).asInstanceOf[WebWorkspace]
    wspace.openString(io.Source.fromURL(url).mkString)
    wspace
  }
  
}
