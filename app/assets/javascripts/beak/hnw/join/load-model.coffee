import AlertDisplay from "/alert-display.js"

import Tortoise from "/beak/tortoise.js"

import genPageTitle      from "../common/gen-page-title.js"
import handleFrameResize from "../common/handle-frame-resize.js"

session = undefined # Session

modelContainer  = document.querySelector("#netlogo-model-container")
loadingOverlay  = document.getElementById("loading-overlay")
activeContainer = loadingOverlay

nlogoScript      = document.querySelector("#nlogo-code")
isStandaloneHTML = nlogoScript.textContent.length > 0
alerter          = new AlertDisplay(document.getElementById("alert-container"), isStandaloneHTML)

# ((Session) => Unit) => (Session) => Unit
openSession = (setSession) -> (s) ->

  session         = s
  document.title  = genPageTitle(session.modelTitle())
  activeContainer = modelContainer

  wc = s.widgetController
  wc.ractive.set("isHNW"    , true )
  wc.ractive.set("isHNWHost", false)

  wc.ractive.fire("unbind-keys")

  session.startLoop()
  session.hnw.subscribe(parent, "load-model::openSession")
  alerter.setWidgetController(wc)
  Tortoise.finishLoading()

  setSession(session)

  return

# ((Session) => Unit) => (Role, View) => Unit
loadHNWModel = (setSession) -> (role, view) ->
  alerter.hide()
  session?.teardown()
  activeContainer = loadingOverlay
  Tortoise.loadHubNetWeb(modelContainer, role, view, openSession(setSession))
  return

handleFrameResize((-> activeContainer), (-> session))

export default loadHNWModel
