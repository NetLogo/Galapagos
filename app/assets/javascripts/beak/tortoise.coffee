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

# (String|DomElement, BrowserCompiler, Array[Rewriter], ModelResult, Boolean, String, Boolean) => SessionLite
newSession = (container, compiler, rewriters, modelResult, readOnly, filename, lastCompileFailed) ->
  { code, info, model: { result }, widgets: wiggies } = modelResult
  widgets = globalEval(wiggies)
  info    = toNetLogoWebMarkdown(info)
  new SessionLite(
    container
  , compiler
  , rewriters
  , widgets
  , code
  , info
  , readOnly
  , filename
  , result
  , lastCompileFailed
  )

# (String) => String
normalizedFileName = (path) ->
  # We separate on both / and \ because we get URLs and Windows-esque filepaths
  pathComponents = path.split(/\/|\\/)
  decodeURI(pathComponents[pathComponents.length - 1])

# (Element, String, String, BrowserCompiler, Array[Rewriter], Model, Boolean) => SessionLite
openSession = (container, modelPath, name, compiler, rewriters, model, lastCompileFailed) ->
  name    = name ? normalizedFileName(modelPath)
  session = newSession(container, compiler, rewriters, model, false, name, lastCompileFailed)
  session

# (() => Unit) => Unit
startLoading = (process) ->
  document.querySelector("#loading-overlay").style.display = ""
  if process?
    # This gives the loading animation time to come up. BCH 7/25/2015
    setTimeout(process, 20)
  return

# () => Unit
finishLoading = ->
  document.querySelector("#loading-overlay").style.display = "none"
  return

fromNlogoSync = (nlogo, container, path, callback, rewriters = []) ->
  segments = path.split(/\/|\\/)
  name     = segments[segments.length - 1]
  compile(container, path, name, nlogo, callback, rewriters)
  return

# (String, Element, String, (Result[SessionLite, Array[CompilerError | String]]) => Unit, Array[Rewriter]) => Unit
fromNlogo = (nlogo, container, path, callback, rewriters = []) ->
  startLoading(->
    fromNlogoSync(nlogo, container, path, callback, rewriters)
    finishLoading()
  )
  return

# (String, String, Element, (Result[SessionLite, Array[CompilerError | String]]) => Unit, Array[Rewriter]) => Unit
fromURL = (url, modelName, container, callback, rewriters = []) ->
  startLoading(() ->
    req = new XMLHttpRequest()
    req.open('GET', url)
    req.onreadystatechange = () ->
      if req.readyState is req.DONE
        if (req.status is 0 or req.status >= 400)
          callback({ type: 'failure', source: 'load-from-url', errors: [url] })
        else
          nlogo = req.responseText
          compile(container, url, modelName, nlogo, callback, rewriters)
        finishLoading()
      return

    req.send("")
    return
  )
  return

compile = (container, modelPath, name, nlogo, callback, rewriters) ->
  compiler = new BrowserCompiler()

  # (ModelCompilation, Boolean) => Unit
  onSuccess = (input, lastCompileFailed) ->
    callback({
      type:    'success'
      session: openSession(container, modelPath, name, compiler, rewriters, input, lastCompileFailed)
    })
    input.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
    rewriters.forEach( (rw) -> rw.compileComplete?() )
    return

  rewriter       = (newCode, rw) -> if rw.injectNlogo? then rw.injectNlogo(newCode) else newCode
  rewrittenNlogo = rewriters.reduce(rewriter, nlogo)
  extrasReducer  = (extras, rw) -> if rw.getExtraCommands? then extras.concat(rw.getExtraCommands()) else extras
  extraCommands  = rewriters.reduce(extrasReducer, [])
  result         = compiler.fromNlogo(rewrittenNlogo, extraCommands)

  if result.model.success
    result.code = if nlogo is rewrittenNlogo then result.code else nlogoToSections(nlogo)[0].slice(0, -1)
    onSuccess(result, false)
  else
    fromNlogoWithoutCode(nlogo, compiler, onSuccess)
    callback({ type: 'failure', source: 'compile', errors: result.model.result })

  return

# (String) => Array[String]
nlogoToSections = (nlogo) ->
  nlogo.split(/^\@#\$#\@#\$#\@$/gm)

# (Array[String]) => String
sectionsToNlogo = (sections) ->
  sections.join('@#$#@#$#@')

# If we have a compiler failure, maybe just the code section has errors.
# We do a second chance compile to see if it'll work without code so we
# can get some widgets/plots on the screen and let the user fix those
# errors up.  -JMB August 2017

# (String, BrowserCompiler, (ModelCompilation, Boolean) => Unit) => Unit
fromNlogoWithoutCode = (nlogo, compiler, onSuccess) ->
  sections = nlogoToSections(nlogo)
  if sections.length isnt 12
    return

  oldCode     = sections[0]
  sections[0] = ''
  newNlogo    = sectionsToNlogo(sections)
  result      = compiler.fromNlogo(newNlogo, [])
  if not result.model.success
    return

  # It mutates state, but it's an easy way to get the code re-added
  # so it can be edited/fixed.
  result.code = oldCode
  onSuccess(result, true)
  return

Tortoise = {
  startLoading,
  finishLoading,
  fromNlogo,
  fromNlogoSync,
  fromURL,
  toNetLogoMarkdown,
  toNetLogoWebMarkdown,
  nlogoToSections,
  sectionsToNlogo
}

if window?
  window.Tortoise  = Tortoise
else
  exports.Tortoise = Tortoise

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval
