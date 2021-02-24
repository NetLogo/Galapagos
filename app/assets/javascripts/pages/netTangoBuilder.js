import "../codemirror-mode.js";
import NetTangoAlertDisplay from "../nettango/nettango-alert-display.js";
import Tortoise from "../beak/tortoise.js";
import newModel from "../new-model.js";
import NetTangoController from "../nettango/nettango-controller.js";
import NetTangoStorage from "../nettango/storage.js";

const pathSplits = location.pathname.split("/")
const hostPrefix = `${location.protocol}//${location.host}${pathSplits.length > 2 ? "/" + pathSplits[1] : ""}`

const modelContainer   = document.getElementById("netlogo-model-container")
const builderContainer = document.getElementById("ntb-container")

var session
function openSession(s) {
    session         = s
    document.title  = pageTitle(session.modelTitle())
    session.startLoop()
    alerter.listenForErrors(session.widgetController)
}

const recompileContainer = document.getElementById("model-recompile-overlay")
const alerter            = new NetTangoAlertDisplay(document.getElementById("alert-container"), window.isStandaloneHtml, recompileContainer)

function pageTitle(modelTitle) {
    return `NetLogo Web ${(modelTitle != null && modelTitle != "") ? ": " + modelTitle : ""}`
}

function handleCompileResult(callback) {
    return (result) => {
        if (result.type === 'success') {
            openSession(result.session)
            if (callback !== undefined) {
                callback()
            }
        } else {
            if (result.source === 'compile-recoverable') {
                openSession(result.session)
            }
            alerter.reportCompilerErrors(result.source, result.errors)
        }
    }
}

function loadModel(nlogo, path, callback) {
    if (session) {
        session.teardown()
    }
    Tortoise.fromNlogoSync(nlogo, modelContainer, path, handleCompileResult(callback), [netTango.rewriter, netTango.compileAlert])
    Tortoise.finishLoading()
}

function loadUrl(url, modelName, callback) {
    if (session) {
        session.teardown()
    }
    Tortoise.fromURL(url, modelName, modelContainer, handleCompileResult(callback), [netTango.rewriter, netTango.compileAlert])
}

function enableFrameSizeUpdates() {
    var width = 0
    var height = 0
    const update = () => {
        if (builderContainer.offsetWidth !== width || builderContainer.offsetHeight !== height) {
            width  = builderContainer.offsetWidth
            height = builderContainer.offsetHeight
            parent.postMessage({
                width:  builderContainer.offsetWidth
                , height: builderContainer.offsetHeight
                , type:   "ntb-resize"
            }, "*")
        }
    }
    window.setInterval(update, 300)
}

window.addEventListener("message", function (e) {
    if (e.data.type === "nlw-load-model") {
        loadModel(e.data.nlogo, e.data.path)
    } else if (e.data.type === "nlw-open-new") {
        loadModel(newModel, "NewModel")
    } else if (e.data.type === "nlw-load-url") {
        loadUrl(e.data.url, e.data.name)
    } else if (e.data.type === "nlw-update-model-state") {
        session.widgetController.setCode(e.data.codeTabContents)
    } else if (e.data.type === "run-baby-behaviorspace") {
        var reaction =
            function(results) {
                e.source.postMessage({ type: "baby-behaviorspace-results", id: e.data.id, data: results }, "*")
            }
        session.asyncRunBabyBehaviorSpace(e.data.config, reaction)
    }
})

if (parent !== window) {
    enableFrameSizeUpdates()
}

window.modelContainer = modelContainer
var ntangoCode        = document.getElementById("ntango-code")

var theOutsideWorld = {
    setModelCode:        loadModel
    , loadUrl:             loadUrl
    , getSession:          ()                => session
    , getWorkspace:        ()                => window.workspace
    , addEventListener:    (event, callback) => document.addEventListener(event, callback)
    , saveAs:              window.saveAs
    , newModel:            newModel
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

var netTango = new NetTangoController(
    "ntb-components",
    ls,
    playMode || window.isStandaloneHtml,
    window.environmentMode,
    theOutsideWorld
)
alerter.listenForNetTangoErrors(netTango)

window.ractive   = netTango.ractive
window.onload    = () => netTango.start(netTangoModelUrl)
