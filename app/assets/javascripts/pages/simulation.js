import { createNotifier, listenerEvents } from "/notifications/listener-events.js";
import { createDebugListener } from "/notifications/debug-listener.js";
import { createIframeRelayListener } from "/notifications/iframe-relay-listener.js";
import { attachQueryHandler } from "/queries/iframe-query-handler.js";

import { fakeStorage, NamespaceStorage } from "/namespace-storage.js";
import { WipListener } from "/beak/wip-listener.js";

import "/codemirror-mode.js";
import AlertDisplay from "/alert-display.js";
import newModel from "/new-model.js";
import Settings from "/settings.js";
import { initSettingsStorage } from "/settings-storage.js";
import Tortoise from "/beak/tortoise.js";

var loadingOverlay  = document.getElementById('loading-overlay');
var activeContainer = loadingOverlay;
var modelContainer  = document.querySelector('#netlogo-model-container');
var nlogoScript     = document.querySelector('#nlogo-code');

const params    = new URLSearchParams(window.location.search);
const paramKeys = Array.from(params.keys());
if (paramKeys.length === 1) {
  const maybeUrl = paramKeys[0];
  if (maybeUrl.startsWith('http') && params.get(maybeUrl) === '') {
    params.delete(maybeUrl);
    params.set('url', maybeUrl);
    window.location.search = params.toString();
  }
}

var ls;
try {
  ls = window.localStorage;
} catch (exception) {
  ls = fakeStorage();
}

const settingsStorage = initSettingsStorage(ls);
const settings = new Settings();
settings.applyStorage(settingsStorage);
settings.applyQueryParams(params);
const listeners = [];

const [wipListener, getWorkInProgress] = (() => {
  if (settings.workInProgress.enabled) {
    const storage = new NamespaceStorage('netLogoWebWip', ls);
    // There is a bit of a circular dep as the `wipListener` is one of the `listeners` fed to `SessionLite`, but the
    // `wipListener` needs to `getNlogo()` from the `SessionLite`.  Since the tangle is event-based I'm not too worried
    // about it, but ideally the nlogo info maintainer could be separate from both and passed in to both.  -Jeremy B
    // January 2023
    const wl = new WipListener(storage, settings.workInProgress.storageTag);
    const gwip = (nlogoSource) => {
      wl.setNlogoSource(nlogoSource);
      const wipInfo = wl.getWip();
      if (wipInfo !== null) {
        nlogoSource.setModelTitle(wipInfo.title);
        return wipInfo.nlogo;
      }
      return nlogoSource.nlogo;
    }
    listeners.push(wl);
    return [wl, gwip];
  } else {
    return [null, null];
  }
})();

var pageTitle = function(modelTitle) {
  if (modelTitle != null && modelTitle != '') {
    return 'NetLogo Web: ' + modelTitle;
  } else {
    return 'NetLogo Web';
  }
}

globalThis.session = null;

var openSession = function(s) {
  globalThis.session = s;
  if (settings.workInProgress.enabled) {
    wipListener.setSession(globalThis.session);
  }
  globalThis.session.widgetController.ractive.set('speed', settings.speed);
  globalThis.session.widgetController.ractive.set('isVertical', settings.useVerticalLayout);
  document.title = pageTitle(globalThis.session.modelTitle());
  activeContainer = modelContainer;
  globalThis.session.startLoop();
  alerter.setWidgetController(globalThis.session.widgetController);
}

const isStandaloneHTML = (nlogoScript.textContent.length > 0);
const isInFrame        = parent !== window;
const alerter          = new AlertDisplay(document.getElementById('alert-container'), isStandaloneHTML);
const alertDialog      = document.getElementById('alert-dialog');
listeners.push(alerter);

function handleCompileResult(result) {
  if (result.type === 'success') {
    openSession(result.session);
  } else {
    if (result.source === 'compile-recoverable') {
      openSession(result.session);
    } else {
      activeContainer = alertDialog;
      loadingOverlay.style.display = 'none';
    }
    notifyListeners('compiler-error', result.source, result.errors);
  }
}

if (settings.events.enableDebug) {
  const debugListener = createDebugListener(listenerEvents);
  listeners.push(debugListener);
}
if (isInFrame && settings.events.enableIframeRelay) {
  const relayListener = createIframeRelayListener(listenerEvents, settings.events.iframeRelayEvents, settings.events.iframeRelayEventsTag);
  listeners.push(relayListener);
}

const notifyListeners = createNotifier(listenerEvents, listeners);

if (isInFrame) {
  const getSession = () => { return globalThis.session };
  attachQueryHandler(getSession);
}

var loadModel = function(nlogo, sourceType, path, isUndoReversion) {
  alerter.hide();
  if (globalThis.session) {
    globalThis.session.teardown();
  }
  activeContainer = loadingOverlay;
  const nlogoSource = Tortoise.createSource(sourceType, path, nlogo);
  Tortoise.fromNlogo(
    nlogoSource
  , modelContainer
  , settings.locale
  , isUndoReversion
  , getWorkInProgress
  , handleCompileResult
  , []
  , listeners
  );
}

const redirectOnProtocolMismatch = function(url) {
  const uri = new URL(url);
  if ('https:' === uri.protocol || 'http:' === window.location.protocol) {
    // we only care if the model is HTTP and the page is HTTPS. -Jeremy B May 2021
    return true;
  }

  const loc         = window.location;
  const isSameHost  = uri.hostname === loc.hostname;
  const isCCL       = uri.hostname === 'ccl.northwestern.edu';
  const port        = isSameHost && window.debugMode ? '9443' : '443';
  const newModelUrl = `https://${uri.hostname}:${port}${uri.pathname}`;

  // if we're in an iframe we can't even reliably make a link to use
  // so just alert the user.
  if (!isSameHost && !isCCL && isInFrame) {
    alerter.reportProtocolError(uri, newModelUrl);
    activeContainer = alertDialog;
    loadingOverlay.style.display = 'none';
    return false;
  }

  var newSearch = '';
  if (params.has('url')) {
    params.set('url', newModelUrl);
    newSearch = params.toString();
  } else {
    newSearch = newModelUrl;
  }

  const newHref = `https://${loc.host}${loc.pathname}?${newSearch}`;

  // if we're not on the same host the link might work, but let
  // the user know and let them click it.
  if (!isSameHost && !isCCL) {
    alerter.reportProtocolError(uri, newModelUrl, newHref);
    activeContainer = alertDialog;
    loadingOverlay.style.display = 'none';
    return false;
  }

  window.location.href = newHref;
  return false;
}

if (nlogoScript.textContent.length > 0) {
  const nlogo  = nlogoScript.textContent;
  const path   = nlogoScript.dataset.filename;
  notifyListeners('model-load', 'script-element');
  const nlogoSource = Tortoise.createSource('script-element', path, nlogo);
  Tortoise.fromNlogo(
    nlogoSource
  , modelContainer
  , settings.locale
  , false
  , getWorkInProgress
  , handleCompileResult
  , []
  , listeners
  );

} else if (params.has('url')) {
  const url = params.get('url').trim();

  if (!url.startsWith('http') || redirectOnProtocolMismatch(url)) {
    notifyListeners('model-load', 'url', url);
    Tortoise.fromURL(
      url
    , modelContainer
    , settings.locale
    , getWorkInProgress
    , handleCompileResult
    , []
    , listeners
    );
  }

} else {
  notifyListeners('model-load', 'new-model');
  loadModel(newModel, 'new', 'NewModel', false);
}

window.addEventListener('message', function (e) {
  switch (e.data.type) {
    case 'nlw-load-model': {
      notifyListeners('model-load', 'file', e.data.path);
      loadModel(e.data.nlogo, 'disk', e.data.path, false);
      break;
    }
    case 'nlw-open-new': {
      notifyListeners('model-load', 'new-model');
      params.delete('url');
      window.location.search = params.toString();
      loadModel(newModel, 'new', 'NewModel', false);
      break;
    }
    case 'nlw-revert-wip': {
      notifyListeners('revert-work-in-progress');
      wipListener.revertWip();
      const nlogoSource = wipListener.getNlogoSource();
      loadModel(
        nlogoSource.nlogo
      , nlogoSource.type
      , nlogoSource.type === "url" ? encodeURI(nlogoSource.url) : nlogoSource.fileName
      , false
      );
      break;
    }
    case 'nlw-undo-revert': {
      notifyListeners('undo-revert');
      wipListener.undoRevert();
      const nlogoSource = wipListener.getNlogoSource();
      loadModel(
        nlogoSource.nlogo
      , nlogoSource.type
      , nlogoSource.type === "url" ? encodeURI(nlogoSource.url) : nlogoSource.fileName
      , true
      );
      break;
    }
    case 'nlw-update-model-state': {
      globalThis.session.widgetController.setCode(e.data.codeTabContents);
      break;
    }
    case 'run-baby-behaviorspace': {
      var reaction =
        function(results) {
          e.source.postMessage({ type: 'baby-behaviorspace-results', id: e.data.id, data: results }, '*')
        };
        globalThis.session.asyncRunBabyBehaviorSpace(e.data.config, reaction);
      break;
    }
    case "nlw-request-model-state": {
      const update = session.hnw.getModelState();
      e.source.postMessage({ update, type: "nlw-state-update", sequenceNum: -1 }, "*");
      break;
    }
    case "nlw-export-model": {
      var model = globalThis.session.getNlogo();
      e.source.postMessage({ type: "nlw-export-model-results", id: e.data.id, export: model }, "*");
      break;
    }
    case "nlw-request-view": {
      const base64 = session.widgetController.viewController.view.visibleCanvas.toDataURL("image/png");
      e.source.postMessage({ base64, type: "nlw-view" }, "*");
      break;
    }
    case "nlw-subscribe-to-updates": {
      session.hnw.subscribe(e.ports[0], "Standard sim");
      break;
    }
    case "nlw-apply-update": {

      const { plotUpdates, viewUpdate } = e.data.update;

      if ((viewUpdate?.world && viewUpdate.world[0]?.ticks) !== undefined) {
        world.ticker.reset();
        world.ticker.importTicks(viewUpdate.world[0].ticks);
      }

      const vc = session.widgetController.viewController;
      vc.applyUpdate(viewUpdate);
      vc.repaint();

      break;

    }
  }
})

if (isInFrame) {
  var width = '', height = '';
  window.setInterval(function() {
    if (
      globalThis.session && (
        activeContainer.offsetWidth  !== width ||
        activeContainer.offsetHeight !== height ||
        document.title != pageTitle(globalThis.session.modelTitle())
      )
    ) {
      document.title = pageTitle(globalThis.session.modelTitle());
      width = activeContainer.offsetWidth;
      height = activeContainer.offsetHeight;
      parent.postMessage({
        width:  activeContainer.offsetWidth,
        height: activeContainer.offsetHeight,
        title:  document.title,
        type:   'nlw-resize'
      }, '*');
    }
  }, 200);
}
