package models

import
  org.nlogo.compile.front.Colorizer

case class CompilationBundle(js: String, rawNlogoCode: String) {
  lazy val colorizedNlogoCode = rawNlogoCode.lines.map(Colorizer.toHtml).mkString("", "\n", "\n")
}
