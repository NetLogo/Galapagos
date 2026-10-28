import { createDebugListener } from "/notifications/debug-listener.js"
import { listenerEvents } from "/notifications/listener-events.js"
import { createIframeRelayListener } from "/notifications/iframe-relay-listener.js";
import { netTangoEvents } from "/nettango/nettango-events.js"

import "/codemirror-mode.js"
import Settings from "/settings.js"
import NetTangoAlertDisplay from "/nettango/nettango-alert-display.js"
import NetTangoController from "/nettango/nettango-controller.js"
import { fakeStorage, NamespaceStorage } from "/namespace-storage.js"
import { bodyMarginWidth, fitViewportToWidth } from "/viewport-fit.js"

const builderContainer = document.getElementById("ntb-container")

function enableFrameSizeUpdates() {
  var width = 0
  var height = 0
  const update = () => {
    if (builderContainer.scrollWidth !== width || builderContainer.scrollHeight !== height) {
      width  = builderContainer.scrollWidth
      height = builderContainer.scrollHeight
      parent.postMessage({
          width:  builderContainer.scrollWidth
        , height: builderContainer.scrollHeight
        , type:   "ntb-resize"
      }, "*")
    }
  }
  window.setInterval(update, 300)
}

function enableViewportFit() {
  var fitWidth = 0
  const fit = () => {
    const pageWidth = builderContainer.scrollWidth + bodyMarginWidth(document.body)
    if (pageWidth !== fitWidth) {
      fitWidth = pageWidth
      fitViewportToWidth(pageWidth)
    }
  }
  const timer = window.setInterval(fit, 300)
  document.addEventListener("pointerdown", () => window.clearInterval(timer), { once: true, capture: true })
}

var storage
try {
  storage = window.localStorage
} catch (exception) {
  storage = fakeStorage()
}

const params           = new URLSearchParams(window.location.search)
const settingsStorage  = new NamespaceStorage('netLogoWebSettings', storage)
const settings         = new Settings()
settings.applyStorage(settingsStorage)
settings.applyQueryParams(params)
const netTangoModelUrl = params.get("netTangoModel")
const playModeParam    = params.get("playMode")
const playMode         = (playModeParam && playModeParam === "true")

if (parent !== window) {
  enableFrameSizeUpdates()
} else if (playMode || window.isStandaloneHTML) {
  enableViewportFit()
}

const alerter = new NetTangoAlertDisplay(document.getElementById("alert-container"), window.isStandaloneHTML)
const listeners = [alerter]

const allEvents = listenerEvents.concat(netTangoEvents)

if (settings.events.enableDebug) {
  const debugListener = createDebugListener(allEvents)
  listeners.push(debugListener)
}
if (settings.events.enableIframeRelay) {
  const relayListener = createIframeRelayListener(allEvents, settings.events.iframeRelayEvents, settings.events.iframeRelayEventsTag)
  listeners.push(relayListener)
}
const disableAutoStore = params.has('disableAutoStore')

const netTango = new NetTangoController(
  "ntb-container"
, settings.locale
, storage
, playMode || window.isStandaloneHTML
, window.environmentMode
, disableAutoStore
, netTangoModelUrl
, listeners
)

const netLogoListeners = listeners.slice(0)
var lastNlogo = ""
const runIfDifferent = (f) => {
  const nlogoResult = netTango.netLogoModel.oracle.getNlogo()
  if (nlogoResult.success) {
    if (nlogoResult.result !== lastNlogo) {
      lastNlogo = nlogoResult.result
      netTango.handleProjectChange()
    }
  }
}
const netLogoWipListener = {
  'recompile-complete':   runIfDifferent
, 'new-widget-finalized': runIfDifferent
, 'widget-updated':       runIfDifferent
, 'widget-deleted':       runIfDifferent
, 'widget-moved':         runIfDifferent
, 'info-updated':         runIfDifferent
, 'title-changed':        runIfDifferent
}
netLogoListeners.push(netLogoWipListener)

alerter.setNetTangoController(netTango)
netTango.netLogoModel.alerter = alerter
netTango.netLogoModel.listeners = netLogoListeners

window.ractive = netTango.ractive
