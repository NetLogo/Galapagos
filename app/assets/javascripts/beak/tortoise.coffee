import SessionLite from "./session-lite.js"
import { toNetLogoWebMarkdown, normalizedFileName, nlogoToSections, sectionsToNlogo } from "./tortoise-utils.js"

# (String|DomElement, BrowserCompiler, Array[Rewriter], ModelResult, Boolean, String, Boolean) => SessionLite
newSession = (container, compiler, rewriters, modelResult, readOnly, filename, lastCompileFailed) ->
  { code, info, model: { result }, widgets: wiggies } = modelResult
  widgets = globalEval(wiggies)
  info    = toNetLogoWebMarkdown(info)
  new SessionLite(
    Tortoise
  , container
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

# (String, Element, String, (Result[SessionLite, Array[CompilerError | String]]) => Unit, Array[Rewriter]) => Unit
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

  rewriter       = (newCode, rw) -> if rw.injectNlogo? then rw.injectNlogo(newCode) else newCode
  rewrittenNlogo = rewriters.reduce(rewriter, nlogo)
  extrasReducer  = (extras, rw) -> if rw.getExtraCommands? then extras.concat(rw.getExtraCommands()) else extras
  extraCommands  = rewriters.reduce(extrasReducer, [])
  result         = compiler.fromNlogo(rewrittenNlogo, extraCommands)

  if result.model.success
    result.code = if nlogo is rewrittenNlogo then result.code else nlogoToSections(nlogo)[0].slice(0, -1)
    callback({
      type:    'success'
    , session: openSession(container, modelPath, name, compiler, rewriters, result, false)
    })
    result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
    rewriters.forEach( (rw) -> rw.compileComplete?() )

  else
    secondChanceResult = fromNlogoWithoutCode(nlogo, compiler)
    if secondChanceResult?
      callback({
        type:        'failure'
      , source:      'compile-recoverable'
      , session:     openSession(container, modelPath, name, compiler, rewriters, secondChanceResult, true)
      , errors:      result.model.result
      })
      result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
      rewriters.forEach( (rw) -> rw.compileComplete?() )

    else
      callback({
        type:        'failure'
      , source:      'compile-fatal'
      , errors:      result.model.result
      })

  return

# If we have a compiler failure, maybe just the code section has errors.
# We do a second chance compile to see if it'll work without code so we
# can get some widgets/plots on the screen and let the user fix those
# errors up.  -JMB August 2017

# (String, BrowserCompiler) => null | ModelCompilation
fromNlogoWithoutCode = (nlogo, compiler) ->
  sections = nlogoToSections(nlogo)
  if sections.length isnt 12
    return null

  oldCode     = sections[0]
  sections[0] = ''
  newNlogo    = sectionsToNlogo(sections)
  result      = compiler.fromNlogo(newNlogo, [])
  if not result.model.success
    return null

  # It mutates state, but it's an easy way to get the code re-added
  # so it can be edited/fixed.
  result.code = oldCode
  return result

Tortoise = {
  startLoading,
  finishLoading,
  fromNlogo,
  fromNlogoSync,
  fromURL,
}

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

export default Tortoise
