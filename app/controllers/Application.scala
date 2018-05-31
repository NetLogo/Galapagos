// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  javax.inject.{ Inject }

import
  models.ModelsLibrary,
    ModelsLibrary.{ allModels, prettyFilepath }

import
  play.api.{ Environment, libs, Logger, mvc },
    libs.json.Json,
    mvc.{ AbstractController, Action, AnyContent, ControllerComponents }

import play.twirl.api.Html

class Application @Inject() ( assets: Assets
                            , components: ControllerComponents
                            , environment: Environment
                            )  extends AbstractController(components) {

  private implicit val mode = environment.mode

  // scalastyle:off public.methods.have.type
  def authoring   = themedPage(views.html.authoring()  , "NetLogo Web Docs - Authoring")
  def differences = themedPage(views.html.differences(), "NetLogo Web vs. NetLogo"     , None            , codeMirrorHtml)
  def faq         = themedPage(views.html.faq()        , "NetLogo Web FAQ")
  def index       = themedPage(views.html.index()      , "NetLogo Web")
  def serverError = themedPage(views.html.serverError(), "NetLogo Web - Error")
  def whatsNew    = themedPage(views.html.whatsNew()   , "What's New in NetLogo Web"   , Option("updates"))
  // scalastyle:on public.methods.have.type

  def model(modelName: String): Action[AnyContent] = {
    Logger.info("\"%s\" requested".format(modelName))
    assets.versioned(path="/public/modelslib", modelName)
  }

  def modelList: Action[AnyContent] = Action {
    implicit request =>
      Ok(Json.stringify(Json.toJson(allModels.map(prettyFilepath))))
  }

  def robots: Action[AnyContent] =
    assets.versioned(path="/public/text", "robots.txt")

  def humans: Action[AnyContent] =
    assets.versioned(path="/public/text", "humans.txt")

  def favicon: Action[AnyContent] =
    assets.versioned(path="/public/images", file = "favicon.ico")

  private def themedPage( html: Html, title: String, selectedTopLink: Option[String] = None
                        , extraHead: Html = Html("")): Action[AnyContent] =
    Action { implicit request => Ok(views.html.mainTheme(html, title, selectedTopLink, extraHead)) }

  private lazy val codeMirrorHtml: Html = {

    def resolve(p: String)   = routes.Assets.versioned(p)
    def linkTag(x: String)   = s"""<link rel="stylesheet" media="screen" href="$x">"""
    def scriptTag(x: String) = s"""<script src="$x"></script>"""

    val cssURLs = Seq( "lib/codemirror/lib/codemirror"
                     , "stylesheets/netlogo-syntax"
                     ).map((x) => resolve(s"$x.css").toString)
    val cssTags = cssURLs.map(linkTag)

    val jsURLs = Seq( "lib/codemirror"
                    , "addon/dialog/dialog"
                    , "addon/mode/simple"
                    , "addon/search/searchcursor"
                    , "addon/search/search"
                    ).map((x) => resolve(s"lib/codemirror/$x.js").toString)
    val jsTags = jsURLs.map(scriptTag)

    val modeJSURLs = Seq( "keywords"
                        , "codemirror-mode"
                        ).map((x) => resolve(s"javascripts/$x.js").toString)
    val modeJSTags = modeJSURLs.map(scriptTag)

    Html((cssTags ++ jsTags ++ modeJSTags).mkString("\n"))

  }

}
