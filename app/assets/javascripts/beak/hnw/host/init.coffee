import newModel  from "/new-model.js"

import applyUpdate          from "./apply-update.js"
import becomeOracle         from "./become-oracle.js"
import handleDisconnect     from "./handle-disconnect.js"
import handleWidgetMessage  from "./handle-widget-message.js"
import handleWindowMessage  from "./handle-window-message.js"
import { loadInitialModel } from "./load-model.js"
import sendInitialState     from "./send-initial-state.js"

babyMonitor     = null # MessagePort
session         = null # Session
widgetTemplates =   {} # Object[String, Array[Widget, Array[P13N]]]

getBabyMonitor     = -> babyMonitor
getRole            = (name) -> getRoles()[name]
getRoleByIndex     = ((i) -> rs = getRoles(); rs[Object.keys(rs)[i]])
getRoles           = -> session.widgetController.ractive.get('hnwRoles')
getSession         = -> session
getWidgetTemplates = (roleName) -> widgetTemplates[roleName]

addWidgetTemplate = (roleName, template, personalizations) ->
  if not widgetTemplates[roleName]?
    widgetTemplates[roleName] = []
  widgetTemplates[roleName].push([template, personalizations])
  return

setBabyMonitor = (bm) ->
  babyMonitor = bm
  return

setRoles = (roles) ->
  session.widgetController.ractive.set('hnwRoles', roles)
  Object.keys(roles).forEach(
    (roleName) ->
      if not widgetTemplates[roleName]?
        widgetTemplates[roleName] = []
  )
  return

setSession = (sesh) ->
  session = sesh
  return

getClientObj = -> session.widgetController.ractive.get('hnwClients')

getClient = (token) -> getClientObj()[token]

getClientIDsWithOutput = ->

  roles = getRoles()

  hasOutput = (rn) -> rn? and roles[rn].widgets.some((w) -> w.type is "hnwOutput")

  Object.entries(getClientObj()).
    filter(([ , { roleName }]) -> hasOutput(roleName)).
    map(([uuid, ]) -> uuid)

registerClient = (token, client) ->
  getClientObj()[token] = client
  return

unregisterClient = (token) ->
  delete getClientObj()[token]
  return

onWidgetMessage = handleWidgetMessage(getClient, getRole, getSession)

onRainCheckMessage = (e) ->
  imageBase64 = session.hnw.cashRainCheckFor(e.data.hash)
  imageUpdate = { type: "import-drawing", imageBase64, hash: e.data.hash, x: e.data.x, y: e.data.y }
  viewUpdate  = { drawingEvents: [imageUpdate] }
  session.hnw.narrowcastUpdate(e.data.token, "nlw-state-update", { viewUpdate })

requestInitialState =
  sendInitialState( getSession, getRoleByIndex, getBabyMonitor
                  , getWidgetTemplates, registerClient)

oraclize = becomeOracle( getBabyMonitor, getSession, setSession, setRoles
                       , registerClient, getClientIDsWithOutput, addWidgetTemplate)

notifyDisconnect = handleDisconnect(getClient, unregisterClient, getRole, getSession)

onBabyMonitorMessage = (e) ->
  switch (e.data.type)

    when "hnw-recompile"

      successCallback = ->
        ractive = session.widgetController.ractive
        ractive.fire("hnw-compilation-success", e.data.code)

      session.widgetController.setCode(e.data.code)
      session.recompile(successCallback)

    when "hnw-console-run"
      session.run("console", e.data.code)

    when "hnw-setup-button"
      session.widgetController.ractive.fire("hnw-setup")

    when "hnw-go-checkbox"
      session.widgetController.ractive.set("isHNWTicking", e.data.goStatus)

    when "hnw-widget-message"
      onWidgetMessage(e)

    when "hnw-cash-raincheck"
      onRainCheckMessage(e)

    when "hnw-become-oracle"
      oraclize(e)

    when "hnw-notify-congested"
      session.hnw.enableCongestionControl()

    when "hnw-notify-uncongested"
      session.hnw.disableCongestionControl()

    when "hnw-request-initial-state"
      requestInitialState(e)

    when "hnw-notify-disconnect"
      notifyDisconnect(e)

    when "nlw-request-view"

      respondWithView =
        ->
          respondent = e.ports?[0] ? babyMonitor
          session.widgetController.viewController.view.visibleCanvas.toBlob(
            (blob) -> respondent.postMessage({ blob, type: "nlw-view" })
          )

      session.widgetController.viewController.repaint()
      setTimeout(respondWithView, 0)
      # Relinquish control for a sec so `repaint` can go off --Jason B. (9/8/20)

    when "hnw-latest-ping"
      getClient(e.data.joinerID)?.ping = e.data.ping

    when "nlw-state-update", "nlw-apply-update"
      applyUpdate(-> session.widgetController)(e)

    else
      console.warn("Unknown babyMon message type:", e.data)

loadInitialModel(setSession)

handleMessage =
  handleWindowMessage( onWidgetMessage, onRainCheckMessage, getSession
                     , setSession, setBabyMonitor, onBabyMonitorMessage)

window.addEventListener("message", handleMessage)
