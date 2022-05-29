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
 * sure that you understand Galapagos#326 before you do!)  --Jason B. (1/26/16)
 */
trait TagBuilder {
  def pathToHTML(path: String, attributes: (String, String)*)(implicit request: Request[_], environment: Environment): Html
  def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_], environment: Environment):            Html
}

object TagBuilder {
  def protocolRelativeURL(url: URL): String =
    s"//${url.getAuthority}${url.getFile}"

  def makeTag(tagName: String, content: String, attributes: Map[String, String]): Html = {
    val attributesString = " " + attributes.map({ case (name, value) => s"""$name="$value"""" }).mkString(" ")
    Html(s"""<$tagName $attributesString>$content</$tagName>""")
  }
}

object InlineTagBuilder extends TagBuilder {

  override def pathToHTML(path: String, attributes: (String, String)*)(implicit request: Request[_], environment: Environment): Html =
    pathToTag(s"public/$path", attributes)

  override def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_], environment: Environment): Html =
    pathToTag(resourcePath)

  private def pathToTag(path: String, attributes: Seq[(String, String)] = Seq.empty)(implicit environment: Environment): Html = {
    val (source, url) = pathToSource(path)
    genTag(source, url, attributes)
  }

  private def pathToSource(path: String)(implicit environment: Environment): (String, URL) = {
    val url    = environment.resource(path).getOrElse(throw new Exception(s"Unknown resource: $path"))
    val source = usingSource(_.fromURL(url))(_.mkString)
    (source, url)
  }

  private def genTag(source: String, url: URL, attributes: Seq[(String, String)] = Seq.empty): Html = {
    val FileExtensionRegex      = ".*\\.(.*)$".r
    val FileExtensionRegex(ext) = url.toString
    ext match {
      case "js"  => TagBuilder.makeTag("script", source, attributes.toMap)
      case "css" => TagBuilder.makeTag("style",  source, attributes.toMap)
      case x     => throw new Exception(s"We don't know how to build a tag for '.$x' files")
    }
  }

}

object OutsourceTagBuilder extends TagBuilder {

  override def pathToHTML(path: String, attributes: (String, String)*)(implicit request: Request[_], environment: Environment): Html =
    genTag(routes.Assets.versioned(path).relative, attributes)

  override def callToHTML(call: Call, resourcePath: String)(implicit request: Request[_], environment: Environment): Html =
    genTag(call.relative)

  private def genTag(protoRelativeURL: String, attributes: Seq[(String, String)] = Seq.empty): Html = {
    val FileExtensionRegex      = ".*\\.(.*)$".r
    val FileExtensionRegex(ext) = protoRelativeURL
    ext match {
      case "js"  => TagBuilder.makeTag("script", "", attributes.toMap + ("src" -> protoRelativeURL) )
      case "css" => TagBuilder.makeTag("link",   "", attributes.toMap + ("rel" -> "stylesheet") + ("href" -> protoRelativeURL))
      case x     => throw new Exception(s"We don't know how to build a tag for '.$x' files")
    }
  }

}
