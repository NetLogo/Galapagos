class window.NetTangoRewriter
  @BEGIN = "; --- NETTANGO BEGIN ---"
  @END   = "; --- NETTANGO END ---"
  @MODIFY_WARNING =
    "; This block of code was added by the NetTango builder.  If you modify this code" +
    "\n; and re-import it into the NetTango builder you may lose your changes or need" +
    "\n; to resolve some errors manually." +
    "\n\n; If you do not plan to re-import the model into the NetTango builder then you" +
    "\n; can safely edit this code however you want, just like a normal NetLogo model."

  constructor: (@getNetTangoCode, @getNetTangoSpaces) ->
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

  # () => Array[String]
  getExtraCommands: () =>
    spaces = @getNetTangoSpaces()
    NetTangoRewriter.createSpacesVariables(spaces)

  # (String) => String
  rewriteNetLogoCode: (code) ->
    alteredCode  = NetTangoRewriter.addNetTangoExtension(code)
    netTangoCode = @getNetTangoCode()
    "#{alteredCode}\n\n#{netTangoCode}\n"

  # (String, String, Array[Error]) => Array[Error]
  updateErrors: (original, rewritten, errors) ->
    errors.map( (error) ->
      declaration = NetTangoRewriter.extensionsDeclarationCheck.exec(original)
      if (not declaration?)
        error.lineNumber = error.lineNumber - 1

      if error.lineNumber > original.split("\n").length
        # the line number is meaningless if it's NetTango injected code causing the error
        delete error.lineNumber
        # coffeelint: disable=max_line_length
        error.message = "The blocks code contains an error and cannot be compiled.  You can try undoing the last block change or checking the error message to try to locate the problem.<br/><br/>The error message is: #{error.message}"
        # coffeelint: enable=max_line_length

      return error
    )

  # (Sring, Int, Int, Int) => String
  @formatAttributeVariable: (containerId, blockId, instanceId, attributeId) ->
    return "\"__#{containerId}_#{blockId}_#{instanceId}_#{attributeId}\""

  # (String, Int, Int, Int, Any) => String
  @formatSetAttribute: (containerId, blockId, instanceId, attributeId, value) ->
    variableName = NetTangoRewriter.formatAttributeVariable(containerId, blockId, instanceId, attributeId)
    "nt:set #{variableName} (#{value})"

  # (String, Int, Int, Int, Any) => String
  @formatCodeAttribute: (containerId, blockId, instanceId, attributeId, value) ->
    variableName = NetTangoRewriter.formatAttributeVariable(containerId, blockId, instanceId, attributeId)
    "(nt:get #{variableName})"

  # (String, Int, Int, Int, Any) => String
  @formatDisplayAttribute: (_0, _1, _2, _3, value) ->
    if typeof(value) is "string"
      "(\"#{value}\")"
    else
      "(#{value})"

  # (String, NetTangoBlock) => Array[String]
  @createBlockVariables: (spaceId, block) ->
    childVariables     = (block.children ? []).flatMap( (child)  =>
      NetTangoRewriter.createBlockVariables(spaceId, child)
    )
    clauseVariables    = (block.clauses  ? []).flatMap( (clause) =>
      NetTangoRewriter.createBlockVariables(spaceId, clause)
    )
    attributeVariables = (block.params   ? []).concat(block.properties ? []).map( (p) ->
      value = p.expressionValue ? p.value
      NetTangoRewriter.formatSetAttribute("#{spaceId}-canvas", block.id, block.instanceId, p.id, value)
    )
    attributeVariables.concat(childVariables).concat(clauseVariables)

  # (Space) => Array[String]
  @createSpaceVariables: (space) ->
    if (not space.defs.program? or not space.defs.program.chains?)
      return []
    space.defs.program.chains.flatMap( (chain) ->
      chain.blocks.flatMap( (block) -> NetTangoRewriter.createBlockVariables(space.spaceId, block) )
    )

  # (Array[Space]) => Array[String]
  @createSpacesVariables: (spaces) ->
    spaces.flatMap( NetTangoRewriter.createSpaceVariables )

  @extensionsDeclarationCheck: /([\s\S]*^\s*extensions(?:\s|;.*\n)*\[)([\s\S]*)/mgi
  @netTangoExtensionCheck: /^\s*extensions(?:\s|;.*\n)*\[(?:\s|;.*\n|\w+)*\bnt\b/mgi

  # (String) => String
  @addNetTangoExtension: (code) ->
    declaration = NetTangoRewriter.extensionsDeclarationCheck.exec(code)
    NetTangoRewriter.extensionsDeclarationCheck.lastIndex = 0
    if (not declaration?)
      return "extensions [ nt ]\n#{code}"

    extension = NetTangoRewriter.netTangoExtensionCheck.test(code)
    NetTangoRewriter.netTangoExtensionCheck.lastIndex = 0
    if (extension)
      return code

    return "#{declaration[1]} nt #{declaration[2]}"

  # (String) => String
  @removeOldNetTangoCode: (code) ->
    code.replace(new RegExp("((?:^|\n)#{NetTangoRewriter.BEGIN}\n)([^]*)(\n#{NetTangoRewriter.END})"), "")
