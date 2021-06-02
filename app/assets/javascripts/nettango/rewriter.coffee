class window.NetTangoRewriter
  @BEGIN = "; --- NETTANGO BEGIN ---"
  @END   = "; --- NETTANGO END ---"
  @MODIFY_WARNING =
    "; This block of code was added by the NetTango builder.  If you modify this code" +
    "\n; and re-import it into the NetTango builder you may lose your changes or need" +
    "\n; to resolve some errors manually." +
    "\n\n; If you do not plan to re-import the model into the NetTango builder then you" +
    "\n; can safely edit this code however you want, just like a normal NetLogo model."

  constructor: (@getNetTangoCode, @getNetTangoSpaces, @isDebugMode) ->
    return

  # (String) => String
  injectCode: (code) =>
    @rewriteNetLogoCode(code)

  # (String) => String
  injectNlogo: (nlogo) =>
    sections    = Tortoise.nlogoToSections(nlogo)
    sections[0] = @rewriteNetLogoCode(sections[0])
    Tortoise.sectionsToNlogo(sections)

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
