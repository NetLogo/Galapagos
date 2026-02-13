import { createNotifier, listenerEvents } from "/notifications/listener-events.js";
import { createDebugListener } from "/notifications/debug-listener.js";
import { createIframeRelayListener } from "/notifications/iframe-relay-listener.js";
import { attachQueryHandler } from "/queries/iframe-query-handler.js";

import { fakeStorage, NamespaceStorage } from "/namespace-storage.js";
import { WipListener } from "/beak/wip-listener.js";

import "/codemirror-mode.js";
import AlertDisplay from "/alert-display.js";
import { newModel } from "/new-model.js";
import Settings from "/settings.js";
import { initSettingsStorage } from "/settings-storage.js";
import Tortoise from "/beak/tortoise.js";

try {

  var loadingState    = 'in-progress'; // 'in-progress' | 'session-open' | 'fatal-error' | 'fatal-error-displayed'
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

  if (params.get("errCode") === "1") {
    throw new Error("Throwing an error as the `errCode` query parameter was set to `1`.  This is only meant for testing and should not be used otherwise.");
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
    if (settings.title) {
      globalThis.session.widgetController.ractive.set('modelTitle', settings.title);
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
    switch (result.type) {
      case 'success':
        openSession(result.session);
        loadingState = 'session-open';
        break;

      case 'model-load-failed':
        notifyListeners('model-load-failed', result.source, result.location, result.errors);
        loadingState = 'fatal-error';
        break;

      default:
        if (result.source === 'compile-recoverable') {
          openSession(result.session);
          loadingState = 'session-open';
          // Just to note it here, this is for displaying recoverable compile-time errors to the user.  If a non-recoverable
          // error occured that should be handled in the `compile-complete` event with a `status: failure`.  -Jeremy B
          // December 2025
          notifyListeners('compiler-error', result.source, result.errors);
        } else {
          loadingState = 'fatal-error';
          activeContainer = document.getElementById('alert-dialog');
          loadingOverlay.style.display = 'none';
        }
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
    if (e.data === null || typeof(e.data) !== 'object') {
      return;
    }

    // If you're running through an iframe you can post a message to the simulation environment like so:
    // `document.getElementById('model-container').contentWindow.postMessage(message, '*')` That assumes your iframe element
    // has an `id="model-container"`.
    // Examples of message structures are given for some of the commands.
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
      // nlw-set-model-code EXAMPLE:
      // {
      //   type: 'nlw-set-model-code',
      //   codeTabContents: 'globals [ var-1 var-2 ]\nto setup\n  show "setup"\nend\nto go\n  show "go"\nend',
      //   autoRecompile: false
      // }
      case 'nlw-set-model-code': {
        globalThis.session.widgetController.setCode(e.data.codeTabContents, e.data.autoRecompile);
        break;
      }
      // nlw-recompile EXAMPLE:
      // { type: 'nlw-recompile' }
      case 'nlw-recompile': {
        globalThis.session.recompile('system');
        break;
      }
      // nlw-recompile-procedures EXAMPLE:
      // {
      //   type: 'nlw-recompile-procedures',
      //   proceduresCode: 'to go show "go has been replaced!" end to setup show "setup has been replaced!" end',
      //   procedureNames: ['GO', 'SETUP'],
      //   autoRerunForevers: true
      // }
      // NOTE: This does not update the code tab contents in the UI.  If you want that updated, too, you'll need to use
      // `nlw-set-model-code` with `autoRecompile: false`.
      case 'nlw-recompile-procedures': {
        const wc = globalThis.session.widgetController
        wc.pauseForevers()
        const rerun = e.data.autoRerunForevers ? wc.rerunForevers : () => {}
        globalThis.session.recompileProcedures(e.data.proceduresCode, e.data.procedureNames, rerun)
        break;
      }
      // nlw-run-code EXAMPLE:
      // { type: 'nlw-run-code', code: 'setup' }
      case 'nlw-run-code': {
        globalThis.session.run('console', e.data.code)
        break;
      }
      // nlw-create-widget EXAMPLES:
      // {
      //   type: 'nlw-create-widget'
      // , widgetType: 'switch'
      // , x: 0, y: 10
      // , properties: { variable: 'show-labels?', display: 'show-labels?', on: true, width: 120 }
      // }
      // {
      //   type: 'nlw-create-widget'
      // , widgetType: 'slider'
      // , x: 0, y: 0
      // , properties: { 'default': 50, 'direction': "horizontal", 'display': 'slider-var1', 'max': "100", 'min': "0", 'step': "1", 'units': null, 'variable': 'slider-var1' }
      // }
      // {
      //   type: 'nlw-create-widget'
      // , widgetType: 'monitor'
      // , x: 0, y: 0
      // , properties: { display: 'blue car avg', source: 'mean [speed] of (turtles with [color = blue])'  }
      // }
      // NOTE: For a list of properties for each widget type, see `widget-properties.coffee`.  You might also want to
      // check the `genProps()` methods on the widget Ractives to see how NLW expects the values presented.  For
      // example, the `variable` property is expected to be lowercase for widgets that have it, and the `min`, `max`,
      // and `step` for sliders take string values instead of numbers because they can be NetLogo code (reporters).
      // Defaults for unset values are found in the `defaultWidgetMixinFor()` function in `widget-controller.coffee` and
      // they'll be used if you don't provide a value. Posts back a message with the new widget ID.
      case 'nlw-create-widget': {
        const { widgetType, x, y, properties } = e.data;
        try {
          const id = globalThis.session.widgetController.createWidgetExternal(widgetType, x, y, properties);
          e.source.postMessage({ type: 'nlw-create-widget-response', succcess: true, 'newWidgetId': id }, "*");
        } catch(err) {
          e.source.postMessage({ type: 'nlw-create-widget-response', success: false, error: err }, "*");
        }
        break;
      }
      // nlw-update-widget EXAMPLE:
      // { type: 'nlw-update-widget', id: 4, properties: { display: 'Setup Sphere Demo' }}
      case 'nlw-update-widget': {
        const { id, properties } = e.data;
        try {
          globalThis.session.widgetController.updateWidgetExternal(id, properties);
          e.source.postMessage({ type: 'nlw-update-widget-response', succcess: true }, "*");
        } catch(err) {
          e.source.postMessage({ type: 'nlw-update-widget-response', success: false, error: err }, "*");
        }
        break;
      }
      // nlw-delete-widget EXAMPLE:
      // { type: 'nlw-delete-widget', id: 14 }
      case 'nlw-delete-widget': {
        const { id } = e.data;
        try {
          globalThis.session.widgetController.deleteWidgetExternal(id);
          e.source.postMessage({ type: 'nlw-delete-widget-response', succcess: true }, "*");
        } catch(err) {
          e.source.postMessage({ type: 'nlw-delete-widget-response', success: false, error: err }, "*");
        }
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
    const adjustSizeAndTitle = () => {
      switch (loadingState) {
        case 'session-open':
          const needsActiveUpdate = activeContainer.offsetWidth !== width ||
            activeContainer.offsetHeight !== height ||
            document.title != pageTitle(globalThis.session.modelTitle());
          if (needsActiveUpdate) {
            document.title = pageTitle(globalThis.session.modelTitle());
            width  = activeContainer.offsetWidth;
            height = activeContainer.offsetHeight;
            parent.postMessage({
              width,
              height,
              title:  document.title,
              type:   'nlw-resize'
            }, '*');
          }
          break;

        case 'fatal-error':
          loadingState = 'fatal-error-displayed'
          const alertContainer = document.getElementById('alert-dialog');
          height = alertContainer.clientHeight + 40;
          width  = alertContainer.clientWidth  + 60;
          parent.postMessage({
            width,
            height,
            title: document.title,
            type:  'nlw-resize'
          }, '*');
          break;
      }
    };
    window.setInterval(adjustSizeAndTitle, 200);
  }

} catch (ex) {
  AlertDisplay.showEarlyInitFailure(ex)
}
