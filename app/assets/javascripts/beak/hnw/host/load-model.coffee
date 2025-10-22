import AlertDisplay from "/alert-display.js"

import Tortoise                         from "/beak/tortoise.js"
import { NewSource, ScriptSource }      from "/beak/nlogo-source.js"
import { docToNlogoXML, nlogoXMLToDoc } from "/beak/tortoise-utils.js"
import { createCommonArgs }             from "/notifications/listener-events.js"

import genPageTitle from "../common/gen-page-title.js"

session = undefined # Session

modelContainer  = document.querySelector("#netlogo-model-container")
alertDialog     = document.getElementById('alert-dialog')
loadingOverlay  = document.getElementById("loading-overlay")
activeContainer = loadingOverlay

nlogoScript      = document.querySelector("#nlogo-code")
isStandaloneHTML = nlogoScript.textContent.length > 0

listeners = [] # Array[Listener]

aCon    = document.getElementById("alert-container")
alerter = new AlertDisplay(aCon, isStandaloneHTML)
listeners.push(alerter)

afterRecompile = ->
  ractive = session.widgetController.ractive
  code    = ractive.get('lastCompiledCode')
  session.widgetController.ractive.fire("hnw-compilation-success", code)

listeners.push({ "recompile-complete": afterRecompile })


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
    alerter['compiler-error'](createCommonArgs(), result)
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
    Tortoise.fromNlogoXMLSync( source
                             , modelContainer
                             , "en_us"
                             , false
                             , null
                             , openSession(setSession)
                             , []
                             , listeners
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
  Tortoise.fromNlogoXMLSync(
    source
  , modelContainer
  , "en_us"
  , false
  , null
  , handleCR
  , []
  , listeners
  , widgets
  )
  return

# (String) => String
removeHostWidgets = (nlogox) ->
  nlogoDoc       = nlogoXMLToDoc(nlogox)
  widgetsElement = nlogoDoc.querySelector("widgets")
  viewElement    = widgetsElement.querySelector("view")
  widgetsElement.replaceChildren(viewElement)
  docToNlogoXML(nlogoDoc)

export { loadInitialModel, loadModel }
