// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import
  java.net.URL

import
  play.{ api, twirl },
    api.{ Environment, mvc },
      mvc.{ Call, Request },
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
  def pathToHTML(path: String)(implicit request: Request[_], environment: Environment):                     Html
  def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_], environment: Environment): Html
}

object TagBuilder {
  def protocolRelativeURL(url: URL): String =
    s"//${url.getAuthority}${url.getFile}"
}

object InlineTagBuilder extends TagBuilder {

  override def pathToHTML(path: String)(implicit request: Request[_], environment: Environment): Html =
    pathToTag(s"public/$path")

  override def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_], environment: Environment): Html =
    pathToTag(resourcePath)

  private def pathToTag(path: String)(implicit environment: Environment): Html =
    (genTag _).tupled(pathToPair(path))

  private def pathToPair(path: String)(implicit environment: Environment): (String, URL) = {
    val url    = environment.resource(path).getOrElse(throw new Exception(s"Unknown resource: $path"))
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

  override def pathToHTML(path: String)(implicit request: Request[_], environment: Environment): Html =
    genTag(routes.Assets.versioned(path).relative)

  override def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_], environment: Environment): Html =
    genTag(call.relative)

  private def genTag(protoRelativeURL: String): Html = {
    val FileExtensionRegex      = ".*\\.(.*)$".r
    val FileExtensionRegex(ext) = protoRelativeURL
    ext match {
      case "js"  => Html(s"""<script src="$protoRelativeURL"></script>""")
      case "css" => Html(s"""<link rel="stylesheet" href="$protoRelativeURL"></link>""")
      case x     => throw new Exception(s"We don't know how to build a tag for '.$x' files")
    }
  }

}
