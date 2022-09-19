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
    mvc.{ AbstractController, Action, AnyContent, ControllerComponents, Request }

import play.twirl.api.Html

class Application @Inject() (
  assets: Assets
, components: ControllerComponents
, environment: Environment
) extends AbstractController(components) {

  private implicit val mode = environment.mode
  private val logger = Logger("application")

  // scalastyle:off public.methods.have.type
  def authoring    = themedPage((_)   => views.html.authoring()    , "NetLogo Web Docs - Authoring", "../")
  def differences  = themedPage((_)   => views.html.differences()  , "NetLogo Web vs. NetLogo"     , "../", None            , differencesExtraHead)
  def faq          = themedPage((req) => views.html.faq()(req)     , "NetLogo Web FAQ"             , "../")
  def attributions = themedPage((_)   => views.html.attributions() , "NetLogo Web Attributions"    , "../")
  def index        = themedPage((req) => views.html.index()(req)   , "NetLogo Web")
  def serverError  = themedPage((_)   => views.html.serverError()  , "NetLogo Web - Error")
  def whatsNew     = themedPage((req) => views.html.whatsNew()(req), "What's New in NetLogo Web"   , ""   , Option("updates"))
  // scalastyle:on public.methods.have.type

  def model(modelName: String): Action[AnyContent] = {
    logger.info("\"%s\" requested".format(modelName))
    assets.versioned(path = "/public/modelslib", modelName)
  }

  def modelList: Action[AnyContent] = Action {
    implicit request =>
      Ok(Json.stringify(Json.toJson(allModels.map(prettyFilepath))))
  }

  def robots: Action[AnyContent] =
    assets.versioned(path = "/public/text", "robots.txt")

  def humans: Action[AnyContent] =
    assets.versioned(path = "/public/text", "humans.txt")

  def favicon: Action[AnyContent] =
    assets.versioned(path = "/public/images", file = "favicon.ico")

  private def themedPage( html: (Request[_]) => Html, title: String, relativizer: String = "", selectedTopLink: Option[String] = None
                        , extraHead: Html = Html("")): Action[AnyContent] =
    Action { implicit request => Ok(views.html.mainTheme(html(request), title, selectedTopLink, extraHead, Html(""), relativizer)) }

  private lazy val differencesExtraHead: Html = {

    def resolve(p: String)   = routes.Assets.versioned(p)
    def linkTag(x: String)   = s"""<link rel="stylesheet" media="screen" href="$x">"""
    def scriptTag(x: String) = s"""<script src="$x"></script>"""
    def moduleTag(x: String) = s"""<script type="module" src="$x"></script>"""

    val cssURLs = Seq(
      "codemirror/lib/codemirror"
    , "stylesheets/netlogo-syntax"
    ).map( (x) => resolve(s"$x.css").toString )
    val cssTags = cssURLs.map(linkTag)

    val jsURLs = Seq(
      "lib/codemirror"
    , "addon/dialog/dialog"
    , "addon/mode/simple"
    , "addon/search/searchcursor"
    , "addon/search/search"
    ).map( (x) => resolve(s"codemirror/$x.js").toString )
    val jsTags = jsURLs.map(scriptTag)

    val moduleURLs = Seq("pages/differences")
      .map((x) => resolve(s"javascripts/$x.js").toString)
    val moduleTags = moduleURLs.map(moduleTag)

    Html((cssTags ++ jsTags ++ moduleTags).mkString("\n"))

  }

}
