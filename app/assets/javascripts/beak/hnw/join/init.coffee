import setUpBabyMonitor from "./baby-monitor.js"

myRole     = null # Role
myUsername = null # String
session    = null # Session
token      = null # String

getToken = -> token

setToken = (t) ->
  token = t
  return

getSession = -> session

getRole = -> myRole

setSession = (sesh) ->
  session = sesh
  return

setRole = (role) ->
  myRole = role
  return

setUsername = (username) ->
  myUsername = username
  return

initBabyMonitor = setUpBabyMonitor( getSession, setSession, getRole, setRole
                                  , setUsername, getToken, setToken)

window.addEventListener("message", (e) ->

  switch e.data.type

    when "nlw-update-model-state"
      session.widgetController.setCode(e.data.codeTabContents)

    when "nlw-request-model-state"
      update = session.hnw.getModelState(getToken())
      e.source.postMessage({ update, type: "nlw-state-update", sequenceNum: -1 }, "*")

    when "nlw-request-view"

      vc = session.widgetController.viewController
      vc.repaint()

      base64 = vc.view.visibleCanvas.toDataURL("image/png")
      e.source.postMessage({ base64, type: "nlw-view" }, "*")

    when "nlw-subscribe-to-updates"
      session.hnw.subscribe(e.ports[0], "Joiner frame")

    when "hnw-set-up-baby-monitor"
      initBabyMonitor(e)

)

resizer = new ResizeObserver(([{ contentRect: { height, width } }]) ->
  parent.postMessage({ type: "resize-joiner", data: { height, width } }, "*")
)

resizer.observe(document.querySelector(".netlogo-model-container-join"))
