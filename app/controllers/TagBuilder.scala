// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  java.net.URL

import
  play.{ api, twirl },
    api.{ mvc, Play },
      mvc.{ Call, Request },
      Play.current,
    twirl.api.Html

import
  models.Util.usingSource

/*
 * Admittedly, the inclusion of `callToHTML`'s `resourcePath` parameter is a blemish.  It
 * might not even be necessary, but I needed a way to convert a `Call` to its content, and
 * I couldn't find one, so I implemented a half-assed solution that involves also passing in
 * the resource's true path.  It's kind of hacky and isn't future-proof, but I'm not seeing
 * other good options here.  If you find one, feel free to blow it to pieces.  (Also, make
 * sure that you understand Galapagos#326 before you do!)  --JAB (1/26/16)
 */
trait TagBuilder {
  def pathToHTML(path: String)(implicit request: Request[_]):                     Html
  def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_]): Html
}

object InlineTagBuilder extends TagBuilder {

  private val pathToTag = pathToPair _ andThen (genTag _).tupled

  override def pathToHTML(path: String)(implicit request: Request[_]): Html =
    pathToTag(s"public/$path")

  override def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_]): Html =
    pathToTag(resourcePath)

  private def pathToPair(path: String): (String, URL) = {
    val url    = Play.resource(path).getOrElse(throw new Exception(s"Unknown resource: $path"))
    val source = usingSource(_.fromURL(url))(_.mkString)
    (source, url)
  }

  private def genTag(source: String, url: URL): Html = {
    val FileExtensionRegex      = ".*\\.(.*)$".r
    val FileExtensionRegex(ext) = url.toString
    ext match {
      case "js"  => Html(s"""<script>$source</script>""")
      case "css" => Html(s"""<style>$source</style>""")
      case x     => throw new Exception(s"We don't know how to build a tag for '.$x' files")
    }
  }

}

object OutsourceTagBuilder extends TagBuilder {

  override def pathToHTML(path: String)(implicit request: Request[_]): Html =
    genTag(routes.Assets.at(path).absoluteURL)

  override def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_]): Html =
    genTag(call.absoluteURL)

  private def genTag(url: String): Html = {
    val FileExtensionRegex      = ".*\\.(.*)$".r
    val FileExtensionRegex(ext) = url
    ext match {
      case "js"  => Html(s"""<script src="$url"></script>""")
      case "css" => Html(s"""<link rel="stylesheet" href="$url"></link>""")
      case x     => throw new Exception(s"We don't know how to build a tag for '.$x' files")
    }
  }

}
