class window.NetTangoRewriter

  constructor: (@compileComplete, @getNetTangoCode) ->
    return

  # (String) => String
  injectCode: (code)  =>
    @rewriteNetLogoCode(code)

  # (String) => String
  injectNlogo: (nlogo) =>
    sections    = Tortoise.nlogoToSections(nlogo)
    sections[0] = @rewriteNetLogoCode(sections[0])
    Tortoise.sectionsToNlogo(sections)

  # (String) => String
  rewriteNetLogoCode: (code) ->
    alteredCode  = NetTangoRewriter.addNetTangoExtension(code)
    netTangoCode = @getNetTangoCode()
    "#{alteredCode}\n\n#{netTangoCode}\n"

  # (Sring, Int, Int, Int) => String
  @formatAttributeVariable: (canvasId, blockId, instanceId, attributeId) ->
    return "\"__#{canvasId}_#{blockId}_#{instanceId}_#{attributeId}\""

  # (String, Int, Int, Int, Any) => String
  @formatSetAttribute: (canvasId, blockId, instanceId, attributeId, value) ->
    variableName = NetTangoRewriter.formatAttributeVariable(canvasId, blockId, instanceId, attributeId)
    "nt:set #{variableName} (#{value})"

  # (String, Int, Int, Int, Any) => String
  @formatCodeAttribute: (canvasId, blockId, instanceId, attributeId, value) ->
    variableName = NetTangoRewriter.formatAttributeVariable(canvasId, blockId, instanceId, attributeId)
    "(nt:get #{variableName})"

  # (String, Int, Int, Int, Any) => String
  @formatDisplayAttribute: (_0, _1, _2, _3, value) ->
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
      chain.flatMap( (block) -> NetTangoRewriter.createBlockVariables(space.spaceId, block) )
    )

  # (Array[Space]) => Array[String]
  @createSpacesVariables: (spaces) ->
    spaces.flatMap( NetTangoRewriter.createSpaceVariables )

  # (String) => String
  @addNetTangoExtension: (code) ->
    declarationCheck = /([\s\S]*^\s*extensions(?:\s|;.*\n)*\[)([\s\S]*)/mgi
    declaration = declarationCheck.exec(code)
    if (not declaration?)
      return "extensions [ nt ]\n#{code}"

    extensionCheck = /^\s*extensions(?:\s|;.*\n)*\[(?:\s|;.*\n|\w+)*\bnt\b/mgi
    extension = extensionCheck.test(code)
    if (extension)
      return code

    return "#{declaration[1]} nt #{declaration[2]}"

  # (String) => String
  @removeOldNetTangoCode: (code) ->
    BEGIN = "; --- NETTANGO BEGIN ---"
    END   = "; --- NETTANGO END ---"
    code.replace(new RegExp("((?:^|\n)#{BEGIN}\n)([^]*)(\n#{END})"), "")
