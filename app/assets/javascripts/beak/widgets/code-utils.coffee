class DataTagStoreUtils
  # (String, String) => Element
  @upsert: (name, value) ->
    dataTag = document.querySelector("data[data-name=#{name}]") or document.createElement('data')
    dataTag.dataset['name'] = name
    dataTag.value = value
    document.body.appendChild(dataTag) unless dataTag.isConnected
    dataTag
  
  # (String) => String | undefined
  @retrieve: (name) ->
    dataTag = document.querySelector("data[data-name=#{name}]")
    if dataTag
      return dataTag.value
    return undefined
  
  # (Document) => Void
  @copyAllToDocument: (targetDocument) ->
    dataElements = document.querySelectorAll('data')
    for element in dataElements
      targetDocument.body.appendChild(element)

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

  @dataTagStore: DataTagStoreUtils
    
export default CodeUtils
