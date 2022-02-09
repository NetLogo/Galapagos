import { createDebugListener } from "/debug-listener.js"
import { listenerEvents } from "/listener-events.js"
import { netTangoEvents } from "/nettango/nettango-events.js"

import "/codemirror-mode.js"
import NetTangoAlertDisplay from "/nettango/nettango-alert-display.js"
import NetTangoController from "/nettango/nettango-controller.js"
import NetTangoStorage from "/nettango/storage.js"

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

if (parent !== window) {
  enableFrameSizeUpdates()
}

var ls
try {
  ls = window.localStorage
} catch (exception) {
  ls = NetTangoStorage.fakeStorage()
}

const params           = new URLSearchParams(window.location.search)
const netTangoModelUrl = params.get("netTangoModel")
const playModeParam    = params.get("playMode")
const playMode         = (playModeParam && playModeParam === "true")

const alerter = new NetTangoAlertDisplay(document.getElementById("alert-container"), window.isStandaloneHtml)
const listeners = [alerter]

const allEvents = listenerEvents.concat(netTangoEvents)

if (params.has('debugEvents')) {
  const debugListener = createDebugListener(allEvents)
  listeners.push(debugListener)
}
if (params.has('relayIframeEvents')) {
  const relayListener = createIframeRelayListener(params.get('relayIframeEvents'), allEvents)
  listeners.push(relayListener)
}

const netTango = new NetTangoController(
  "ntb-container"
, ls
, playMode || window.isStandaloneHTML
, window.environmentMode
, netTangoModelUrl
, listeners
)
alerter.setNetTangoController(netTango)
netTango.netLogoModel.alerter = alerter
netTango.netLogoModel.listeners = listeners

window.ractive = netTango.ractive
