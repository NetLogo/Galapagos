// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package controllers

import models.Util.usingSource

import
  play.api.Play,
    Play.current

import play.twirl.api.Html

object TemplateUtil {
  private def inlineTag(tag: String, props: String)(url: String): Html = {
    val source = usingSource(_.fromURL(url))(_.mkString)
    Html(s"<$tag $props>$source</$tag>")
  }

  private def outsourceTag(tag: String, props: String, urlProp: String)(url: String): Html = {
    Html(s"""<$tag $props $urlProp="$url"></$tag>""")
  }

  def inlineScript:    (String) => Html = inlineTag("script", "") _
  def outsourceScript: (String) => Html = outsourceTag("script", "", "src") _
  def inlineStyle:     (String) => Html = inlineTag("style", "") _
  def outsourceStyle:  (String) => Html = outsourceTag("link", "rel=\"stylesheet\"", "href") _
}
