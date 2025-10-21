markdownToHtml = (md) ->
  getBase64IfResource = (url) ->
    name = url.getPath()
    if workspace.resources.hasOwnProperty(name)
      resource = workspace.resources[name]
      "data:image/#{resource.extension};base64,#{resource.data}"
    else
      null

  # html_sanitize is provided by Google Caja - see https://code.google.com/p/google-caja/wiki/JsHtmlSanitizer
  # RG 8/18/15
  window.html_sanitize(
    window.markdown.toHTML(md),
    (url) -> if /^https?:\/\//.test(url) then url else getBase64IfResource(url), # URL Sanitizer
    (id) -> id)                                                                  # ID Sanitizer

# (String) => String
toNetLogoWebMarkdown = (md) ->
  md.replace(
    new RegExp('<!---*\\s*((?:[^-]|-+[^->])*)\\s*-*-->', 'g')
    (match, commentText) ->
      "[nlw-comment]: <> (#{commentText.trim()})")

# (String) => String
toNetLogoMarkdown = (md) ->
  md.replace(
    new RegExp('\\[nlw-comment\\]: <> \\(([^\\)]*)\\)', 'g'),
    (match, commentText) ->
      "<!-- #{commentText} -->")

# (String) => String
normalizedFileName = (path) ->
# We separate on both / and \ because we get URLs and Windows-esque filepaths
  pathComponents = path.split(/\/|\\/)
  decodeURI(pathComponents[pathComponents.length - 1])

# (String) => Array[String]
nlogoToSections = (nlogo) ->
  nlogo.split(/^\@#\$#\@#\$#\@$/gm)

# (Array[String]) => String
sectionsToNlogo = (sections) ->
  sections.join('@#$#@#$#@')

# (String) => Document
nlogoXMLToDoc = (nlogox) ->
  parser = new DOMParser()
  parser.parseFromString(nlogox, "text/xml")

# (Document) => String
docToNlogoXML = (nlogoDoc) ->
  serializer = new XMLSerializer()
  serializer.serializeToString(nlogoDoc)

# (String) => String
stripXMLCdata = (xml) ->
  if xml.startsWith("<![CDATA[") and xml.endsWith("]]>")
    xml.slice(9, -3)
  else
    xml

# (String) => String
convertNlogoToXML = (nlogo) ->
  compiler = new BrowserCompiler()
  oldFormatResult = compiler.convertNlogoToXML(nlogo)
  if not oldFormatResult.success
    console.log(oldFormatResult)
    # coffeelint: disable=max_line_length
    err = "Failed to convert old format model to XML.  Make sure the model is a valid NetLogo 6 or 7 model.  The converter gave the error:  #{oldFormatResult.result[0].message}"
    # coffeelint: enable=max_line_length
    throw new Error(err)

  oldFormatResult.result

export {
  markdownToHtml,
  toNetLogoWebMarkdown,
  toNetLogoMarkdown,
  normalizedFileName,
  nlogoToSections,
  sectionsToNlogo,
  nlogoXMLToDoc,
  docToNlogoXML,
  stripXMLCdata,
  convertNlogoToXML
}
