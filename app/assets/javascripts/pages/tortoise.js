import { bindModelChooser, selectModel, selectModelByURL, handPickedModels } from "/models.js"

var modelContainer = document.querySelector('#model-container');
var hostPrefix     = location.protocol + '//' + location.host;
var pathSplits = location.pathname.split("/")
if(pathSplits.length > 2) {
  hostPrefix = hostPrefix + "/" + pathSplits[1]
}

var modelFileInput = document.querySelector('#model-file-input');
modelFileInput.addEventListener('click', function (event) { this.value = '' })
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
  pickModel(model + ".nlogo");
}

function openModelFromUrl(url) {
  if (decodeURI(url) === url) {
    url = encodeURI(url);
  }
  if (url === "Load") {
    selectModel("Select a model");
    if (modelContainer.contentWindow.location == "about:blank") {
      modelContainer.contentWindow.location.replace("./web");
      modelFileInput.value = "";
    }
  } else if (url === "NewModel") {
    selectModel("Select a model");
    modelContainer.contentWindow.location.replace("./web");
    modelFileInput.value = "";
  } else {
    selectModelByURL(url);
    var query = (window.location.search === "") ? url : `url=${url}&${window.location.search.slice(1)}`;
    modelContainer.contentWindow.location.replace(`./web?${query}`);
    modelFileInput.value = "";
  }
}

window.addEventListener("hashchange", function(e) {
  var url = window.location.hash.slice(1);
  openModelFromUrl(url);
})

window.addEventListener("message", function(e) {

  if (e.data.type === "nlw-resize") {

    var isValid = function(x) { return (typeof x !== "undefined" && x !== null); };

    var height = e.data.height;
    var width  = e.data.width;
    var title  = e.data.title;

    // Quack, quack!
    // Who doesn't love duck typing? --JAB (11/9/15)
    if ([height, width, title].every(isValid)) {
      modelContainer.width               = width;
      // When we reset the model height, we lose any scrolling that was in place,
      // so we "copy" it back to the main document.  -Jeremy B March 2021
      const modelScrollTop               = modelContainer.contentDocument.body.scrollTop
      modelContainer.height              = height;
      document.documentElement.scrollTop = document.documentElement.scrollTop + modelScrollTop
      document.title                     = title;
    }

  } else if (e.data.type === "nlw-set-hash") {
    window.location.hash = e.data.hash;
  }

});

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
      modelContainer.contentWindow.location.replace("./web");
    } else {
      openModelFromUrl(hash);
    }
  } else {
    pickRandom();
  }
}

bindModelChooser(document.getElementById('tortoise-model-list')
               , initModel, pickModel, window.environmentMode);
