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

  # (String, String, Array[Error]) => Array[Error]
  updateErrors: (original, rewritten, errors) ->
    errors.map( (error) ->
      if error.lineNumber > original.split("\n").length
        # the line number is meaningless if it's NetTango injected code causing the error
        delete error.lineNumber
        # coffeelint: disable=max_line_length
        error.message = "The blocks code contains an error and cannot be compiled.  You can try undoing the last block change or checking the error message to try to locate the problem.<br/><br/>The error message is: #{error.message}"
        # coffeelint: enable=max_line_length

      return error
    )

  # (String, Integer, Integer, Integer, String, String) => String
  @formatDisplayAttribute: (_0, _1, _2, _3, value, attributeType) ->
    if (attributeType is 'select' and value.length > 0 and value.charAt(0) isnt '"')
      "(#{value})"
    else
      value

  # (String) => String
  @removeOldNetTangoCode: (code) ->
    code.replace(new RegExp("((?:^|\n)#{NetTangoRewriter.BEGIN}\n)([^]*)(\n#{NetTangoRewriter.END})"), "")
