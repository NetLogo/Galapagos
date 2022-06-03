import WidgetController from "./widget-controller.js"
import { setUpWidgets } from "./set-up-widgets.js"
import generateRactiveSkeleton from "./skeleton.js"
import handleWidgetSelection from "./handle-widget-selection.js"
import handleContextMenu from "./handle-context-menu.js"
import controlEventTraffic from "./event-traffic-control.js"
import genConfigs from "./config-shims.js"
import ViewController from "./draw/view-controller.js"

defaultView =
  { dimensions: {
      maxPxcor:           0
      maxPycor:           0
      minPxcor:           0
      minPycor:           0
      patchSize:          1
      wrappingAllowedInX: false
      wrappingAllowedInY: false
    }
    fontSize:         0
    frameRate:        0
    showTickCounter:  true
    tickCounterLabel: "ticks"
    type:             "dummy-view"
    updateMode:       "TickBased"
  }

# (Element|String, Array[Widget], String, String,
#   Boolean, NlogoSource, String, String, BrowserCompiler, () => Unit) => WidgetController
initializeUI = (containerArg, widgets, code, info,
  isReadOnly, source, workInProgressState, compiler, performUpdate) ->

  container = if typeof(containerArg) is 'string' then document.querySelector(containerArg) else containerArg

  # This sucks. The buttons need to be able to invoke a redraw and widget
  # update (unless we want to wait for the next natural redraw, possibly one
  # second depending on speed slider), but we can't make the controller until
  # the widgets are filled out. So, we close over the `controller` variable
  # and then fill it out at the end when we actually make the thing.
  # BCH 11/10/2014
  controller = null
  updateUI   = ->
    performUpdate()
    controller.updateWidgets()

  # Same as above, need a way to report errors, but we don't have the controller
  # instance yet, so just make the closure.  -Jeremy B March 2021
  reportError = (time, source, exception, ...args) ->
    controller.reportError(time, source, exception, ...args)

  ractive = generateRactiveSkeleton(
      container
    , widgets
    , code
    , info
    , isReadOnly
    , source
    , workInProgressState
    , (code) -> compiler.isReporter(code)
  )

  container.querySelector('.netlogo-model').focus({
    preventScroll: true
  })

  viewWidget =
    widgets.find(({ type }) -> type is 'view' or type is 'hnwView') ? defaultView

  ractive.set('primaryView', viewWidget)
  viewController = new ViewController(container.querySelector('.netlogo-view-container'), viewWidget)

  configs    = genConfigs(ractive, viewController, container, compiler)
  controller = new WidgetController(ractive, viewController, configs, performUpdate)
  setUpWidgets(reportError, widgets, updateUI, controller.plotSetupHelper())
  controlEventTraffic(controller, performUpdate)
  handleWidgetSelection(ractive)
  handleContextMenu(ractive)

  controller

export default initializeUI
