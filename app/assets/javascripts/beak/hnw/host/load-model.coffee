import AlertDisplay from "/alert-display.js"

import Tortoise                    from "/beak/tortoise.js"
import { NewSource, ScriptSource } from "/beak/nlogo-source.js"

import genPageTitle      from "../common/gen-page-title.js"
import handleFrameResize from "../common/handle-frame-resize.js"

session = undefined # Session

modelContainer  = document.querySelector("#netlogo-model-container")
alertDialog     = document.getElementById('alert-dialog')
loadingOverlay  = document.getElementById("loading-overlay")
activeContainer = loadingOverlay

nlogoScript      = document.querySelector("#nlogo-code")
isStandaloneHTML = nlogoScript.textContent.length > 0
alerter          = new AlertDisplay(document.getElementById("alert-container"), isStandaloneHTML)

# ((Session) => Unit) => (Object[Any]) => Unit
handleCompileResult = (setSession) -> (result) ->
  if result.type is 'success'
    openSession(setSession)(result.session)
  else
    if result.source is 'compile-recoverable'
      openSession(setSession)(result.session)
    else
      activeContainer = alertDialog
      loadingOverlay.style.display = "none"
    alerter.reportCompilerErrors(result.source, result.errors)
  return

# ((Session) => Unit) => (Session) => Unit
openSession = (setSession) -> (s) ->
  session         = s
  document.title  = genPageTitle(session.modelTitle())
  activeContainer = modelContainer
  alerter.setWidgetController(session.widgetController)
  session.startLoop()
  if babyMonitor?
    session.hnw.entwineWithIDMan(babyMonitor)
  Tortoise.finishLoading()
  setSession(session)
  return

# ((Session) => Unit) => Unit
loadInitialModel = (setSession) ->
  if nlogoScript.textContent.length > 0
    trimmed = removeHostWidgets(nlogoScript.textContent)
    source  = new ScriptSource(nlogoScript.dataset.filename, trimmed)
    Tortoise.fromNlogoSync( source
                          , modelContainer
                          , "en_us" # TODO: Where am I supposed to get this?
                          , false   # TODO: Eh?
                          , null    # TODO: What is `getWorkInProgress` for?
                          , openSession(setSession)
                          , []      # TODO: Should I have rewriters?
                          , []      # TODO: Should I have listeners?
                          )
  else
    loadModel(setSession)(new NewSource())

  return

# ((Session) => Unit) => (NlogoSource, Array[Widget]) => Unit
loadModel = (setSession) -> (source, widgets = []) ->
  alerter.hide()
  session?.teardown()
  activeContainer = loadingOverlay
  handleCR        = handleCompileResult(setSession)
  source.transform(removeHostWidgets)
  Tortoise.fromNlogoSync(
    source
  , modelContainer
  , "en_us" # TODO: Where am I supposed to get this?
  , false   # TODO: Eh?
  , null    # TODO: What is `getWorkInProgress` for?
  , handleCR
  , []      # TODO: Should I have rewriters?
  , []      # TODO: Should I have listeners?
  , widgets
  )
  return

# (String) => String
removeHostWidgets = (nlogo) ->
  delim                       = "\n@#$#@#$#@\n"
  regex                       = new RegExp(".*?(^GRAPHICS-WINDOW$.*?\n\n).*", "sm")
  [code, widgets, theRest...] = nlogo.split("\n@#$#@#$#@\n")
  newWidgets                  = widgets.replace(regex, "$1")
  [code, newWidgets, theRest...].join(delim)

handleFrameResize((-> activeContainer), (-> session))

export { loadInitialModel, loadModel }
