import { listenForQueryResponses, createQueryMaker } from "/queries/debug-query-maker.js";
import { bindModelChooser, selectModel, selectModelByURL, handPickedModels } from "/models.js";
import Settings from "/settings.js"

var modelContainer = document.querySelector('#model-container');
var hostPrefix     = location.protocol + '//' + location.host;
var pathSplits = location.pathname.split("/");
if (pathSplits.length > 2) {
  hostPrefix = hostPrefix + "/" + pathSplits[1];
}

const params   = new URLSearchParams(window.location.search);
const settings = new Settings();
settings.applyQueryParams(params);

var modelFileInput = document.querySelector('#model-file-input');
modelFileInput.addEventListener('click', function (event) { this.value = '' });
modelFileInput.addEventListener('change', function (event) {
  var reader = new FileReader();
  reader.onload = function (e) {
    openNlogo(e.target.result);
  };
  if (this.files.length > 0) {
    reader.readAsText(this.files[0]);
  }
});

function pickModel(url) {
  var encoded = encodeURI(hostPrefix + '/assets/' + url);
  window.location.hash = encoded;
}

function pickRandom() {
  var model = handPickedModels[Math.floor(Math.random() * handPickedModels.length)];
  selectModel(model);
  pickModel(model + ".nlogox");
}

function openModelFromUrl(url) {
  if (decodeURI(url) === url) {
    url = encodeURI(url);
  }
  if (url === "Load") {
    selectModel("Select a model");
    if (modelContainer.contentWindow.location == "about:blank") {
      modelContainer.contentWindow.location.replace(`./web?${params.toString()}`);
      modelFileInput.value = "";
    }

  } else if (url === "NewModel") {
    selectModel("Select a model");
    params.delete("url");
    modelContainer.contentWindow.location.replace(`./web?${params.toString()}`);
    modelFileInput.value = "";

  } else {
    selectModelByURL(url);
    params.set("url", url);
    modelContainer.contentWindow.location.replace(`./web?${params.toString()}`);
    modelFileInput.value = "";

  }
}

window.addEventListener("hashchange", function(e) {
  var url = window.location.hash.slice(1);
  openModelFromUrl(url);
})

window.addEventListener("message", function(e) {
  if (e.data === null || typeof(e.data) !== 'object') {
    return;
  }

  switch (e.data.type) {

    case "nlw-resize": {

      var isValid = function(x) { return (typeof x !== "undefined" && x !== null) };

      var height = e.data.height;
      var width  = e.data.width;
      var title  = e.data.title;

      // Quack, quack!
      // Who doesn't love duck typing? --Jason B. (11/9/15)
      if ([height, width, title].every(isValid)) {
        modelContainer.width               = width;
        // When we reset the model height, we lose any scrolling that was in place,
        // so we "copy" it back to the main document.  -Jeremy B March 2021
        const modelScrollTop               = modelContainer.contentDocument.body.scrollTop;
        modelContainer.height              = height;
        document.documentElement.scrollTop = document.documentElement.scrollTop + modelScrollTop;
        document.title                     = title;
      }

      break;
    }

    case "nlw-set-hash": {
      window.location.hash = e.data.hash;
      break;
    }

  }

})

function openNlogo(nlogoContents) {
  window.location.hash = "Load";
  var filePath = document.getElementById("model-file-input").value;
  modelContainer.contentWindow.postMessage({
    nlogo: nlogoContents,
    path: filePath,
    type: "nlw-load-model"
  }, "*");
}

function initModel() {
  if (window.location.hash) {
    var hash = window.location.hash.substring(1);
    if (hash === "NewModel") {
      modelContainer.contentWindow.location.replace(`./web?${params.toString()}`);
    } else {
      openModelFromUrl(hash);
    }
  } else {
    pickRandom();
  }
}

bindModelChooser(document.getElementById('tortoise-model-list')
               , initModel, pickModel, window.environmentMode);

if (settings.queries.enableDebug) {
  window.makeQuery = createQueryMaker(modelContainer);
  listenForQueryResponses();
}
