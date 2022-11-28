import "/codemirror-mode.js";
import AlertDisplay from "/alert-display.js";
import newModel from "/new-model.js";
import Tortoise from "/beak/tortoise.js";

var loadingOverlay  = document.getElementById("loading-overlay");
var activeContainer = loadingOverlay;
var modelContainer  = document.querySelector("#netlogo-model-container");
var nlogoScript     = document.querySelector("#nlogo-code");

var pageTitle       = function(modelTitle) {
  if (modelTitle != null && modelTitle != "") {
    return "NetLogo Web: " + modelTitle;
  } else {
    return "NetLogo Web";
  }
};
globalThis.session = null;
var speed = 0.0;
var openSession = function(s) {
  globalThis.session = s;
  globalThis.session.widgetController.ractive.set('speed', speed)
  document.title = pageTitle(globalThis.session.modelTitle());
  activeContainer = modelContainer;
  globalThis.session.startLoop();
  alerter.listenForErrors(globalThis.session.widgetController)
};

const isStandaloneHTML = (nlogoScript.textContent.length > 0);
const isInFrame        = parent !== window
const alerter          = new AlertDisplay(document.getElementById('alert-container'), isStandaloneHTML);
const alertDialog      = document.getElementById('alert-dialog')

function handleCompileResult(result) {
  if (result.type === 'success') {
    openSession(result.session)
  } else {
    if (result.source === 'compile-recoverable') {
      openSession(result.session)
    } else {
      activeContainer = alertDialog
      loadingOverlay.style.display = "none";
    }
    alerter.reportCompilerErrors(result.source, result.errors)
  }
}

var loadModel = function(nlogo, path) {
  alerter.hide()
  if (globalThis.session) {
    globalThis.session.teardown();
  }
  activeContainer = loadingOverlay;
  Tortoise.fromNlogo(nlogo, modelContainer, path, handleCompileResult);
};

const parseFloatOrElse = function(str, def) {
  const f = Number.parseFloat(str)
  return (f !== NaN ? f : def)
}

const clamp = function(min, max, val) {
  return Math.max(min, Math.min(max, val))
}

const readSpeed = function(params) {
  return params.has('speed') ? clamp(-1, 1, parseFloatOrElse(params.get('speed'), 0.0)) : 0.0;
}

const redirectOnProtocolMismatch = function(url) {
  const uri = new URL(url)
  if ("https:" === uri.protocol || "http:" === window.location.protocol) {
    // we only care if the model is HTTP and the page is HTTPS. -Jeremy B May 2021
    return true
  }

  const loc         = window.location
  const isSameHost  = uri.hostname === loc.hostname
  const port        = isSameHost && window.debugMode ? "9443" : "443"
  const newModelUrl = `https://${uri.hostname}:${port}${uri.pathname}`

  // if we're in an iframe we can't even reliably make a link to use
  // so just alert the user.
  if (!isSameHost && isInFrame) {
    alerter.reportProtocolError(uri, newModelUrl)
    activeContainer = alertDialog
    loadingOverlay.style.display = "none";
    return false
  }

  const params  = new URLSearchParams(window.location.search)
  var newSearch = ""
  if (params.has("url")) {
    params.set("url", newModelUrl)
    newSearch = params.toString()
  } else {
    newSearch = newModelUrl
  }

  const newHref = `https://${loc.host}${loc.pathname}?${newSearch}`

  // if we're not on the same host the link might work, but let
  // the user know and let them click it.
  if (!isSameHost) {
    alerter.reportProtocolError(uri, newModelUrl, newHref)
    activeContainer = alertDialog
    loadingOverlay.style.display = "none";
    return false
  }

  window.location.href = newHref
  return false
}

if (nlogoScript.textContent.length > 0) {
  const nlogo  = nlogoScript.textContent;
  const path   = nlogoScript.dataset.filename;
  const params = new URLSearchParams(window.location.search)
  speed        = readSpeed(params)
  Tortoise.fromNlogo(nlogo, modelContainer, path, handleCompileResult);

} else if (window.location.search.length > 0) {
  const params    = new URLSearchParams(window.location.search)
  const url       = params.has('url')  ? params.get('url')             : window.location.search.slice(1);
  const modelName = params.has('name') ? decodeURI(params.get('name')) : undefined;
  speed           = readSpeed(params)

  if (redirectOnProtocolMismatch(url)) {
    Tortoise.fromURL(url, modelName, modelContainer, handleCompileResult);
  }

} else {
  loadModel(newModel, "NewModel");
}

window.addEventListener("message", function (e) {
  switch (e.data.type) {
    case "nlw-load-model": {
      loadModel(e.data.nlogo, e.data.path);
      break;
    }
    case "nlw-open-new": {
      loadModel(newModel, "NewModel");
      break;
    }
    case "nlw-update-model-state": {
      globalThis.session.widgetController.setCode(e.data.codeTabContents);
      break;
    }
    case "run-baby-behaviorspace": {
      var reaction =
        function(results) {
          e.source.postMessage({ type: "baby-behaviorspace-results", id: e.data.id, data: results }, "*");
        };
      globalThis.session.asyncRunBabyBehaviorSpace(e.data.config, reaction);
      break;
    }
    case "nlw-export-model": {
      var model = globalThis.session.getNlogo();
      e.source.postMessage({ type: "nlw-export-model-results", id: e.data.id, export: model }, "*");
      break;
    }
  }
});

if (isInFrame) {
  var width = "", height = "";
  window.setInterval(function() {
    if (activeContainer.offsetWidth  !== width ||
      activeContainer.offsetHeight !== height ||
      (globalThis.session !== null && document.title != pageTitle(globalThis.session.modelTitle()))
    ) {
      if (globalThis.session !== null) {
        document.title = pageTitle(globalThis.session.modelTitle());
      }
      width = activeContainer.offsetWidth;
      height = activeContainer.offsetHeight;
      parent.postMessage({
        width:  activeContainer.offsetWidth,
        height: activeContainer.offsetHeight,
        title:  document.title,
        type:   "nlw-resize"
      }, "*");
    }
  }, 200);
}
