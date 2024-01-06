import SessionLite from "./session-lite.js"
import { DiskSource, NewSource, UrlSource, ScriptSource } from "./nlogo-source.js"
import { toNetLogoWebMarkdown, nlogoToSections, sectionsToNlogo } from "./tortoise-utils.js"
import { createNotifier, listenerEvents } from "../notifications/listener-events.js"

# (String|DomElement, BrowserCompiler, Array[Rewriter], Array[Listener], ModelResult,
#  Boolean, String, String, NlogoSource, Boolean) => SessionLite
newSession = (container, compiler, rewriters, listeners, modelResult,
  isReadOnly, locale, workInProgressState, nlogoSource, lastCompileFailed) ->
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
  , isReadOnly
  , locale
  , workInProgressState
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

# (NlogoSource, Element, String, Boolean,
#   (NlogoSource) => String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromNlogo = (nlogoSource, container, locale, isUndoReversion,
  getWorkInProgress, callback, rewriters = [], listeners = []) ->
  startLoading(->
    fromNlogoSync(nlogoSource, container, locale, isUndoReversion, getWorkInProgress, callback, rewriters, listeners)
    finishLoading()
  )
  return

# (String, Element, String, (NlogoSource) => String, CompileCallback, Array[Rewriter], Array[Listener]) => Unit
fromURL = (url, container, locale, getWorkInProgress, callback, rewriters = [], listeners = []) ->
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
          fromNlogoSync(urlSource, container, locale, false, getWorkInProgress, callback, rewriters, listeners, [])
        finishLoading()
      return

    req.send("")
    return
  )
  return

# (NlogoSource, Element, String, Boolean,
#   (NlogoSource) => String, CompileCallback, Array[Rewriter], Array[Listener],
#   Array[Widget]) => Unit
fromNlogoSync = (nlogoSource, container, locale, isUndoReversion,
  getWorkInProgress, callback, rewriters, listeners, extraWidgets = []) ->

  compiler = new BrowserCompiler()

  notifyListeners = createNotifier(listenerEvents, listeners)

  startingNlogo       = nlogoSource.nlogo
  workInProgressState = 'disabled'
  if getWorkInProgress isnt null
    startingNlogo       = getWorkInProgress(nlogoSource)
    workInProgressState = if isUndoReversion or startingNlogo is nlogoSource.nlogo
      'enabled-and-empty'
    else
      'enabled-with-wip'

  rewriter       = (newCode, rw) -> if rw.injectNlogo? then rw.injectNlogo(newCode) else newCode
  rewrittenNlogo = rewriters.reduce(rewriter, startingNlogo)

  extrasReducer = (extras, rw) -> if rw.getExtraCommands? then extras.concat(rw.getExtraCommands()) else extras
  extraCommands = rewriters.reduce(extrasReducer, [])

  notifyListeners('compile-start', rewrittenNlogo, startingNlogo)
  result = compiler.fromNlogo(rewrittenNlogo, extraCommands, { code: "", widgets: extraWidgets })

  if result.model.success

    result.code = if (startingNlogo is rewrittenNlogo)
      result.code
    else
      nlogoToSections(startingNlogo)[0].slice(0, -1)

    session = newSession(
      container
    , compiler
    , rewriters
    , listeners
    , result
    , false
    , locale
    , workInProgressState
    , nlogoSource
    , false
    )

    callback({
      type:    'success'
    , session
    })
    result.commands.forEach( (c) -> if c.success then (new Function(c.result))() )
    rewriters.forEach( (rw) -> rw.compileComplete?() )

  else
    secondChanceResult = fromNlogoWithoutCode(startingNlogo, compiler)
    if secondChanceResult?
      notifyListeners('compile-complete', rewrittenNlogo, startingNlogo, 'failure', 'compile-recoverable')

      session = newSession(
        container
      , compiler
      , rewriters
      , listeners
      , secondChanceResult
      , false
      , locale
      , workInProgressState
      , nlogoSource
      , true
      )

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
  result      = compiler.fromNlogo(newNlogo, [], { code: "", widgets: [] })
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

# (DOMElement, Role, View, (Session) => Unit, Array[Listener]) => Unit
loadHubNetWeb = (container, role, view, callback, listeners) ->

  adaptedWidgets =
    role.widgets.map(
      (w) ->
        if w.type is "hnwView"
          pWidth    = view.dimensions.maxPxcor - view.dimensions.minPxcor
          patchSize = w.width / pWidth
          updates   = { patchSize, right: w.right + 4, bottom: w.bottom + 4 }
          Object.assign({}, view, w, updates)
        else
          w
    )

  code = """var Updater = new (tortoise_require('engine/updater'))((x) => x);
var world = {};
world.observer = {}
var __hnwGlobals = {};
world.observer.getGlobal = function(varName) { return __hnwGlobals[varName.toLocaleLowerCase()]; };
world.observer.setGlobal = function(varName, value) { __hnwGlobals[varName.toLocaleLowerCase()] = value; };
world.setPatchSize       = function() {};
world.ticker = new (tortoise_require('engine/core/world/ticker'))();
world.ticker._onReset    = function() {};
world.ticker._onTick     = function() {};
world.ticker._updateFunc = function() {};
var workspace = {};
workspace.i18nBundle = { supports: function() { return true; }, 'switch': function() {} };
"""

  getDefault = (w) ->
    switch w.type
      when "hnwChooser"
        "'#{w.choices[w.currentChoice]}'"
      when "hnwInputBox"
        if w.boxedValue.type is "String"
          "'#{w.boxedValue.value}'"
        else
          w.boxedValue.value
      when "hnwSlider"
        w.default
      when "hnwSwitch"
        w.on
      else
        throw new Error("Invalid widget type: #{w.type}")

  varInit =
    adaptedWidgets.
      filter((w) -> w.type in ["hnwChooser", "hnwInputBox", "hnwSlider", "hnwSwitch"]).
      map((w) -> "world.observer.setGlobal('#{w.variable}', #{getDefault(w)});").
      reduce(((acc, x) -> "#{acc}\n#{x}"), "")

  model =
    { code:      "no code"
    , commands:  []
    , info:      "no info"
    , model:     { success: true, result: code + varInit }
    , reporters: []
    , type:      "hnwModelCompilation"
    , widgets:   JSON.stringify(adaptedWidgets)
    }

  compiler =
    { exportNlogo: (-> throw new Error("exportNlogo: This compiler is a stub."))
    , fromModel  : (-> throw new Error("fromModel:   This compiler is a stub."))
    , isReporter : (-> throw new Error("isReporter:  This compiler is a stub."))
    }

  session = newSession( container, compiler, [], listeners, model, false, "en_us"
                      , null, new NewSource(""), false)
  callback(session)

  return

Tortoise = {
  createSource,
  startLoading,
  finishLoading,
  fromNlogo,
  fromNlogoSync,
  fromURL,
  loadHubNetWeb
}

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

export default Tortoise
