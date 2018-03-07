# (Element|String, Array[Widget], String, String, Boolean, String, String, (String) => Boolean) => WidgetController
window.initializeUI = (containerArg, widgets, code, info, isReadOnly, filename, checkIsReporter) ->

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

  window.setUpWidgets(widgets, updateUI)

  ractive = window.generateRactiveSkeleton(container, widgets, code, info, isReadOnly, filename, checkIsReporter)

  container.querySelector('.netlogo-model').focus()

  viewModel = widgets.find(({ type }) -> type is 'view')

  ractive.set('primaryView', viewModel)
  viewController = new ViewController(container.querySelector('.netlogo-view-container'), viewModel.fontSize)

  entwineDimensions(viewModel, viewController.model.world)
  entwine([[viewModel, "fontSize"], [viewController.view, "fontSize"]], viewModel.fontSize)

  configs    = window.genConfigs(ractive, viewController, container)
  controller = new WidgetController(ractive, viewController, configs)

  window.controlEventTraffic(controller)
  window.handleWidgetSelection(ractive)
  window.handleContextMenu(ractive)

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
