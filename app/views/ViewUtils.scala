// (C) Uri Wilensky. https://github.com/NetLogo/Galapagos

package views

object ViewUtils {

  def idSafe(s: String): String = {
    s.replaceAll(" ", "-")
      .replaceAll("[^a-zA-Z0-9\\-_:.]", "")
  }

}
