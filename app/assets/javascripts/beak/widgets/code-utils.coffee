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

class SpeculativeLoadingUtils
  # (String) => Void
  @prefetchAsset: (url) ->
    return unless url
    link = document.createElement('link')
    link.rel = 'prefetch'
    link.href = url
    document.head.appendChild(link)

  # (String) => Void
  @prefetchDocument: (url) ->
    return unless url
    iframe = document.createElement('iframe')
    iframe.style.display = 'none'

    iframe.onload = =>
      resources = []
      doc = iframe.contentDocument

      # This will be null if the URL is cross-origin
      # so it should only be used for same-origin URLs
      if doc
        elements = doc.querySelectorAll('link[rel="stylesheet"], script[src], img[src]')
        for element in elements
          src = element.getAttribute('src') or element.getAttribute('href')
          continue unless src

          sourceURL =
            try new URL(src, doc.baseURI)
            catch
              null
          continue unless sourceURL

          href = sourceURL.href
          resources.push(href)

        for resource in resources
          @prefetchAsset(resource)

      document.body.removeChild(iframe)

    iframe.src = url
    document.body.appendChild(iframe)

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
  @speculativeLoading: SpeculativeLoadingUtils

export default CodeUtils
