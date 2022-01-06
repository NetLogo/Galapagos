import WidgetController from "./widget-controller.js"
import { setUpWidgets } from "./set-up-widgets.js"
import generateRactiveSkeleton from "./skeleton.js"
import handleWidgetSelection from "./handle-widget-selection.js"
import handleContextMenu from "./handle-context-menu.js"
import controlEventTraffic from "./event-traffic-control.js"
import genConfigs from "./config-shims.js"
import ViewController from "./draw/view-controller.js"

# (Element|String, Array[Widget], String, String, Boolean, String, String, BrowserCompiler) => WidgetController
initializeUI = (containerArg, widgets, code, info, isReadOnly, filename, compiler) ->

  container = if typeof(containerArg) is 'string' then document.querySelector(containerArg) else containerArg

  # This sucks. The buttons need to be able to invoke a redraw and widget
  # update (unless we want to wait for the next natural redraw, possibly one
  # second depending on speed slider), but we can't make the controller until
  # the widgets are filled out. So, we close over the `controller` variable
  # and then fill it out at the end when we actually make the thing.
  # BCH 11/10/2014
  controller = null
  updateUI   = ->
    controller.redraw()
    controller.updateWidgets()

  # Same as above, need a way to report errors, but we don't have the controller
  # instance yet, so just make the closure.  -Jeremy B March 2021
  reportError = (time, source, exception) ->
    controller.reportError(time, source, exception)
  setUpWidgets(reportError, widgets, updateUI)

  ractive = generateRactiveSkeleton(
      container
    , widgets
    , code
    , info
    , isReadOnly
    , filename
    , (code) -> compiler.isReporter(code)
  )

  container.querySelector('.netlogo-model').focus({
    preventScroll: true
  })

  viewModel = widgets.find(({ type }) -> type is 'view')

  ractive.set('primaryView', viewModel)
  viewController = new ViewController(container.querySelector('.netlogo-view-container'), viewModel.fontSize)

  entwineDimensions(viewModel, viewController.model.world)
  entwine([[viewModel, "fontSize"], [viewController.view, "fontSize"]], viewModel.fontSize)

  configs    = genConfigs(ractive, viewController, container, compiler)
  controller = new WidgetController(ractive, viewController, configs)

  controlEventTraffic(controller)
  handleWidgetSelection(ractive)
  handleContextMenu(ractive)

  controller

# (Array[(Object[Any], String)], Any) => Unit
entwine = (objKeyPairs, value) ->

  backingValue = value

  for [obj, key] in objKeyPairs
    Object.defineProperty(obj, key, {
      get: -> backingValue
      set: (newValue) -> backingValue = newValue
    })

  return

# (Widgets.View, ViewController.View) => Unit
entwineDimensions = (viewWidget, modelView) ->

  translations = {
    maxPxcor:           "maxpxcor"
  , maxPycor:           "maxpycor"
  , minPxcor:           "minpxcor"
  , minPycor:           "minpycor"
  , patchSize:          "patchsize"
  , wrappingAllowedInX: "wrappingallowedinx"
  , wrappingAllowedInY: "wrappingallowediny"
  }

  for wName, mName of translations
    entwine([[viewWidget.dimensions, wName], [modelView, mName]], viewWidget.dimensions[wName])

  return

export default initializeUI
