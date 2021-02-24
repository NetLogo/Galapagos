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

export {
  toNetLogoWebMarkdown,
  toNetLogoMarkdown,
  normalizedFileName,
  nlogoToSections,
  sectionsToNlogo
}