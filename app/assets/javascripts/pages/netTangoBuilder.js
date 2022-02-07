import "/codemirror-mode.js";
import NetTangoAlertDisplay from "/nettango/nettango-alert-display.js";
import NetTangoController from "/nettango/nettango-controller.js";
import NetTangoStorage from "/nettango/storage.js";

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

const urlParams        = new URLSearchParams(window.location.search)
const netTangoModelUrl = urlParams.get("netTangoModel")
const playModeParam    = urlParams.get("playMode")
const playMode         = (playModeParam && playModeParam === "true")

const alerter = new NetTangoAlertDisplay(document.getElementById("alert-container"), window.isStandaloneHtml)
const listeners = [alerter]
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

window.ractive = netTango.ractive
