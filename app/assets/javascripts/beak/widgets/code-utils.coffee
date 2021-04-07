class CodeUtils
  @procedureNameFinder = /^\s*(?:to|to-report)\s(?:\s*;.*\n)*\s*(\w\S*)/gm

  @findProcedureNames: (code) ->
    procedureNames = {}
    CodeUtils.procedureNameFinder.lastIndex = 0
    while match = CodeUtils.procedureNameFinder.exec(code)
      procedureNames[match[1].toUpperCase()] = match.index + match[0].length
    procedureNames

window.CodeUtils = CodeUtils
