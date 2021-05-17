class CodeUtils
  @procedureNameFinder = /^\s*(?:to|to-report)\s(?:\s*;.*\n)*\s*(\w\S*)/gm

  # (String, "upper" | "lower" | "as-written") => ObjectMap[String, { name: String, loc: Int }]
  @findProcedureNames: (code, caseMode) ->
    changeCase = switch caseMode
      when 'upper'      then (p) -> p.toUpperCase()
      when 'lower'      then (p) -> p.toLowerCase()
      when 'as-written' then (p) -> p
    procedureNames = {}
    CodeUtils.procedureNameFinder.lastIndex = 0
    while match = CodeUtils.procedureNameFinder.exec(code)
      name = changeCase(match[1])
      procedureNames[name] = match.index + match[0].length
    procedureNames

window.CodeUtils = CodeUtils
