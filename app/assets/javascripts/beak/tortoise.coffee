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

# (NlogoSource, Element, (NlogoSource) => String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromNlogo = (nlogoSource, container, getWorkInProgress, callback, rewriters = [], listeners = []) ->
  startLoading(->
    fromNlogoSync(nlogoSource, container, getWorkInProgress, callback, rewriters, listeners)
    finishLoading()
  )
  return

# (String, Element, (NlogoSource) => String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromURL = (url, container, getWorkInProgress, callback, rewriters = [], listeners = []) ->
  startLoading(() ->
    req = new XMLHttpRequest()
    req.open('GET', url)
    req.onreadystatechange = () ->
      if req.readyState is req.DONE
        if (req.status is 0 or req.status >= 400)
          callback({ type: 'failure', source: 'load-from-url', errors: [url] })
        else
          nlogo = req.responseText
          urlSource = new UrlSource(url, nlogo)
          fromNlogoSync(urlSource, container, getWorkInProgress, callback, rewriters, listeners)
        finishLoading()
      return

    req.send("")
    return
  )
  return

# (NlogoSource, Element, (NlogoSource) => String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromNlogoSync = (nlogoSource, container, getWorkInProgress, callback, rewriters, listeners) ->
  compiler = new BrowserCompiler()

  notifyListeners = createNotifier(listenerEvents, listeners)

  startingNlogo = getWorkInProgress(nlogoSource)

  rewriter       = (newCode, rw) -> if rw.injectNlogo? then rw.injectNlogo(newCode) else newCode
  rewrittenNlogo = rewriters.reduce(rewriter, startingNlogo)

  extrasReducer = (extras, rw) -> if rw.getExtraCommands? then extras.concat(rw.getExtraCommands()) else extras
  extraCommands = rewriters.reduce(extrasReducer, [])

  notifyListeners('compile-start', rewrittenNlogo, startingNlogo)
  result = compiler.fromNlogo(rewrittenNlogo, extraCommands)

  if result.model.success
    result.code = if (startingNlogo is rewrittenNlogo)
      result.code
    else
      nlogoToSections(startingNlogo)[0].slice(0, -1)

    notifyListeners('compile-complete', rewrittenNlogo, startingNlogo, 'success')
    session = newSession(container, compiler, rewriters, listeners, result, false, nlogoSource, false)
    callback({
      type:    'success'
    , session: session
    })
    result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
    rewriters.forEach( (rw) -> rw.compileComplete?() )

  else
    secondChanceResult = fromNlogoWithoutCode(startingNlogo, compiler)
    if secondChanceResult?
      notifyListeners('compile-complete', rewrittenNlogo, startingNlogo, 'failure', 'compile-recoverable')
      session = newSession(container, compiler, rewriters, listeners, secondChanceResult, false, nlogoSource, true)
      callback({
        type:    'failure'
      , source:  'compile-recoverable'
      , session: session
      , errors:  result.model.result
      })
      result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
      rewriters.forEach( (rw) -> rw.compileComplete?() )

    else
      notifyListeners('compile-complete', rewrittenNlogo, startingNlogo, 'failure', 'compile-fatal')
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

createSource = (sourceType, path, nlogo) ->
  switch sourceType
    when 'disk'
      new DiskSource(path, nlogo)

    when 'new'
      new NewSource(nlogo)

    when 'script-element'
      new ScriptSource(path, nlogo)

    when 'url'
      new UrlSource(path, nlogo)

Tortoise = {
  createSource,
  startLoading,
  finishLoading,
  fromNlogo,
  fromNlogoSync,
  fromURL
}

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

export default Tortoise
