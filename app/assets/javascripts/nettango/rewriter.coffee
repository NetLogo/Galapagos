import { nlogoToSections, sectionsToNlogo } from "/beak/tortoise-utils.js"
import Rewriter from "/beak/rewriter.js"

class NetTangoRewriter extends Rewriter
  @BEGIN = "; --- NETTANGO BEGIN ---"
  @END   = "; --- NETTANGO END ---"
  @MODIFY_WARNING =
    "; This block of code was added by the NetTango Web Builder.  If you modify this code" +
    "\n; and re-import it into the NetTango Web Builder you may lose your changes or need" +
    "\n; to resolve some errors manually." +
    "\n\n; If you do not plan to re-import the model into the NetTango Web Builder then you" +
    "\n; can safely edit this code however you want, just like a normal NetLogo model."

  constructor: (@getNetTangoCode, @getNetTangoSpaces, @isDebugMode) ->
    super()
    return

  # (String) => String
  injectCode: (code) =>
    @rewriteNetLogoCode(code)

  # (String) => String
  injectNlogo: (nlogo) =>
    sections    = nlogoToSections(nlogo)
    sections[0] = @rewriteNetLogoCode(sections[0])
    sectionsToNlogo(sections)

  exportCode: (code) =>
    netTangoCode = @getNetTangoCode(displayOnly = true)
    "#{code}" +
      "\n#{NetTangoRewriter.BEGIN}" +
      "\n\n#{NetTangoRewriter.MODIFY_WARNING}" +
      "\n\n#{netTangoCode}" +
      "\n#{NetTangoRewriter.END}"

  # (String) => String
  rewriteNetLogoCode: (code) ->
    netTangoCode = @getNetTangoCode()
    if @isDebugMode then console.log("  NetTango code:", netTangoCode)
    "#{code}\n\n#{netTangoCode}\n"

  # (String, Integer, Integer, Integer, String, String) => String
  @formatDisplayAttribute: (_0, _1, _2, _3, value, _4) ->
    value

  # (String) => String
  @removeOldNetTangoCode: (code) ->
    code.replace(new RegExp("((?:^|\n)#{NetTangoRewriter.BEGIN}\n)([^]*)(\n#{NetTangoRewriter.END})"), "")

export default NetTangoRewriter
