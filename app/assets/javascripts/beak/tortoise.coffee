import SessionLite from "./session-lite.js"
import { DiskSource, NewSource, UrlSource, ScriptSource } from "./nlogo-source.js"
import { toNetLogoWebMarkdown, nlogoToSections, sectionsToNlogo } from "./tortoise-utils.js"
import { createNotifier, listenerEvents } from "../notifications/listener-events.js"

# (String|DomElement, BrowserCompiler, Array[Rewriter], Array[Listener], ModelResult, Boolean, NlogoSource, Boolean)
#   => SessionLite
newSession = (container, compiler, rewriters, listeners, modelResult, readOnly, nlogoSource, lastCompileFailed) ->
  { code, info, model: { result }, widgets: wiggies } = modelResult
  widgets = globalEval(wiggies)
  info    = toNetLogoWebMarkdown(info)
  session = new SessionLite(
    Tortoise
  , container
  , compiler
  , rewriters
  , listeners
  , widgets
  , code
  , info
  , readOnly
  , nlogoSource
  , result
  , lastCompileFailed
  )
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

# type CompileCallback = (Result[SessionLite, Array[CompilerError | String]]) => Unit

# (String, Element, String, String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromNlogoSync = (nlogo, container, nlogoSourceType, modelPath, callback, rewriters = [], listeners = []) ->
  nlogoSource = switch nlogoSourceType
    when 'disk'
      new DiskSource(modelPath)

    when 'new'
      new NewSource()

    when 'script-element'
      new ScriptSource(modelPath)

  compile(container, nlogoSource, nlogo, callback, rewriters, listeners)
  return

# (String, Element, String, String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromNlogo = (nlogo, container, source, path, callback, rewriters = [], listeners = []) ->
  startLoading(->
    fromNlogoSync(nlogo, container, source, path, callback, rewriters, listeners)
    finishLoading()
  )
  return

# (String, String, Element, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromURL = (url, modelName, container, callback, rewriters = [], listeners = []) ->
  startLoading(() ->
    req = new XMLHttpRequest()
    req.open('GET', url)
    req.onreadystatechange = () ->
      if req.readyState is req.DONE
        if (req.status is 0 or req.status >= 400)
          callback({ type: 'failure', source: 'load-from-url', errors: [url] })
        else
          nlogo = req.responseText
          urlSource = new UrlSource(url)
          compile(container, urlSource, nlogo, callback, rewriters, listeners)
        finishLoading()
      return

    req.send("")
    return
  )
  return

compile = (container, nlogoSource, nlogo, callback, rewriters, listeners) ->
  compiler = new BrowserCompiler()
  notifyListeners = createNotifier(listenerEvents, listeners)

  rewriter       = (newCode, rw) -> if rw.injectNlogo? then rw.injectNlogo(newCode) else newCode
  rewrittenNlogo = rewriters.reduce(rewriter, nlogo)
  extrasReducer  = (extras, rw) -> if rw.getExtraCommands? then extras.concat(rw.getExtraCommands()) else extras
  extraCommands  = rewriters.reduce(extrasReducer, [])
  notifyListeners('compile-start', rewrittenNlogo, nlogo)
  result         = compiler.fromNlogo(rewrittenNlogo, extraCommands)

  if result.model.success
    result.code = if nlogo is rewrittenNlogo then result.code else nlogoToSections(nlogo)[0].slice(0, -1)
    notifyListeners('compile-complete', rewrittenNlogo, nlogo, 'success')
    callback({
      type:    'success'
    , session: newSession(container, compiler, rewriters, listeners, result, false, nlogoSource, false)
    })
    result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
    rewriters.forEach( (rw) -> rw.compileComplete?() )

  else
    secondChanceResult = fromNlogoWithoutCode(nlogo, compiler)
    if secondChanceResult?
      notifyListeners('compile-complete', rewrittenNlogo, nlogo, 'failure', 'compile-recoverable')
      callback({
        type:    'failure'
      , source:  'compile-recoverable'
      , session: newSession(container, compiler, rewriters, listeners, secondChanceResult, false, nlogoSource, true)
      , errors:  result.model.result
      })
      result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
      rewriters.forEach( (rw) -> rw.compileComplete?() )

    else
      notifyListeners('compile-complete', rewrittenNlogo, nlogo, 'failure', 'compile-fatal')
      callback({
        type:   'failure'
      , source: 'compile-fatal'
      , errors: result.model.result
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

  oldCode     = sections[0].slice(0, -1) # drop the trailing '\n' from the regex
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
