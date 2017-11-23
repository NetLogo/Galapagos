{ eq } = tortoise_require('brazier/equals')

# (Element or string, [widget], string, string, boolean, string) -> WidgetController
window.bindWidgets = (container, widgets, code, info, readOnly, filename) ->
  if typeof container == 'string'
    container = document.querySelector(container)

  # This sucks. The buttons need to be able to invoke a redraw and widget
  # update (unless we want to wait for the next natural redraw, possibly one
  # second depending on speed slider), but we can't make the controller until
  # the widgets are filled out. So, we close over the `controller` variable
  # and then fill it out at the end when we actually make the thing.
  # BCH 11/10/2014
  controller       = null
  updateUICallback = ->
    controller.redraw()
    controller.updateWidgets()
  fillOutWidgets(widgets, updateUICallback)

  sanitizedMarkdown = (md) ->
    # html_sanitize is provided by Google Caja - see https://code.google.com/p/google-caja/wiki/JsHtmlSanitizer
    # RG 8/18/15
    html_sanitize(
      markdown.toHTML(md),
      (url) -> if /^https?:\/\//.test(url) then url else undefined, # URL Sanitizer
      (id) -> id)                                                   # ID Sanitizer

  dropNLogoExtension = (s) ->
    if s.match(/.*\.nlogo/)?
      s.slice(0, -6)
    else
      s

  existsInObj = (f) -> (obj) ->
    for _, v of obj when f(v)
      return true
    false

  model = {
    widgetObj:          widgets.reduce(((acc, widget, index) -> acc[index] = widget; acc), {})
    speed:              0.0,
    ticks:              "", # Remember, ticks initialize to nothing, not 0
    ticksStarted:       false,
    width:              0,
    height:             0,
    code,
    info,
    readOnly,
    lastCompiledCode:   code,
    lastCompileFailed:  false,
    isStale:            false,
    exportForm:         false,
    modelTitle:         dropNLogoExtension(filename),
    consoleOutput:      '',
    outputWidgetOutput: '',
    markdown:           sanitizedMarkdown,
    hasFocus:           false,
    isEditing:          false,
    primaryView:        undefined
  }

  animateWithClass = (klass) ->
    (t, params) ->
      params = t.processParams(params)

      eventNames = ['animationend', 'webkitAnimationEnd', 'oAnimationEnd', 'msAnimationEnd']

      listener = (l) -> (e) ->
        e.target.classList.remove(klass)
        for event in eventNames
          e.target.removeEventListener(event, l)
        t.complete()

      for event in eventNames
        t.node.addEventListener(event, listener(listener))
      t.node.classList.add(klass)

  Ractive.transitions.grow   = animateWithClass('growing')
  Ractive.transitions.shrink = animateWithClass('shrinking')

  ractive = new Ractive({
    el:         container,
    template:   template,
    partials:   partials,
    components: {

      console:       RactiveConsoleWidget
    , contextMenu:   RactiveContextMenu
    , editableTitle: RactiveModelTitle
    , editor:        RactiveEditorWidget
    , infotab:       RactiveInfoTabWidget
    , resizer:       RactiveResizer

    , tickCounter:   RactiveTickCounter

    , labelWidget:   RactiveLabel
    , switchWidget:  RactiveSwitch
    , buttonWidget:  RactiveButton
    , sliderWidget:  RactiveSlider
    , chooserWidget: RactiveChooser
    , monitorWidget: RactiveMonitor
    , inputWidget:   RactiveInput
    , outputWidget:  RactiveOutputArea
    , plotWidget:    RactivePlot
    , viewWidget:    RactiveView

    },
    data: -> model
  })

  container.querySelector('.netlogo-model').focus()
  mousetrap = Mousetrap(container.querySelector('.netlogo-model'))
  mousetrap.bind(['ctrl+shift+alt+i', 'command+shift+alt+i'], => ractive.fire('toggleInterfaceLock'))
  mousetrap.bind(['del', 'backspace']                       , => ractive.fire('deleteSelected'))
  mousetrap.bind('escape'                                   , => ractive.fire('deselectWidgets'))

  viewModel = widgets.filter((w) -> w.type == 'view')[0]
  ractive.set('primaryView', viewModel)
  viewController = new AgentStreamController(container.querySelector('.netlogo-view-container'), viewModel.fontSize)

  setUpDimensionsProxies(viewModel, viewController.model.world)
  fontSizeProxy =
    addProxyTo( viewModel.proxies
              , [[viewModel, "fontSize"], [viewController.view, "fontSize"]]
              , "fontSize"
              , viewModel.fontSize)

  outputWidget = widgets.filter((w) -> w.type == 'output')[0]

  plotOps = createPlotOps(container, widgets)

  clearMouse = ->
    viewController.mouseDown = false
    return

  mouse = {
    peekIsDown: -> viewController.mouseDown
    peekIsInside: -> viewController.mouseInside
    peekX: viewController.mouseXcor
    peekY: viewController.mouseYcor
  }

  write = (str) -> model.consoleOutput += str

  output = {
    clear:
      () ->
        output = ractive.findComponent('outputWidget')
        if (output?) then output.setText('')
    write:
      (str) ->
        output = ractive.findComponent('outputWidget')
        if (output?)
          output.appendText(str)
        else
          model.consoleOutput += str
  }

  # `yesOrNo` should eventually be changed to use a proper synchronous, three-button,
  # customizable dialog... when HTML and JS start to support that. --JAB (6/1/16)
  dialog = {
    confirm: (str) -> clearMouse(); window.confirm(str)
    input:   (str) -> clearMouse(); window.prompt(str, "")
    notify:  (str) -> clearMouse(); window.nlwAlerter.display("NetLogo Notification", true, str)
    yesOrNo: (str) -> clearMouse(); window.confirm(str)
  }

  worldConfig = {
    resizeWorld: ->

      runningForeverButtons =
        widgets.filter(
          ({ type, forever, running }) ->
              type is "button" and forever and running
        )

      runningForeverButtons.forEach((button) -> button.running = false)

      return

  }

  importExport = {
    exportOutput: (filename) ->
      exportText = ractive.findComponent('outputWidget')?.get('text') ? ractive.findComponent('console').get('output')
      exportBlob = new Blob([exportText], {type: "text/plain:charset=utf-8"})
      saveAs(exportBlob, filename)
      return
    exportView: (filename) ->
      anchor = document.createElement("a")
      anchor.setAttribute("href", viewController.view.visibleCanvas.toDataURL("img/png"))
      anchor.setAttribute("download", filename)
      anchor.click()
      return
  }

  ractive.observe('widgetObj.*.currentValue', (newVal, oldVal, keyPath, widgetNum) ->
    widget = @get('widgetObj')[widgetNum]
    if widget.variable? and world? and newVal != oldVal and isValidValue(widget, newVal)
      world.observer.setGlobal(widget.variable, newVal)
  )

  ractive.observe('widgetObj.*.right', ->
    @set('width', Math.max.apply(Math, w.right for own i, w of @get('widgetObj') when w.right?))
  )

  ractive.observe('widgetObj.*.bottom', ->
    @set('height', Math.max.apply(Math, w.bottom for own i, w of @get('widgetObj') when w.bottom?))
  )

  ractive.on('checkFocus', (_, node) ->
    @set('hasFocus', document.activeElement is node)
  )

  ractive.on('checkActionKeys', (_, e) ->
    if @get('hasFocus')
      char = String.fromCharCode(if e.which? then e.which else e.keyCode)
      for _, w of @get('widgetObj') when w.type is 'button' and
                                         w.actionKey is char and
                                         ractive.findAllComponents('buttonWidget').
                                           find((b) -> b.get('widget') is w).get('isEnabled')
        w.run()
  )

  ractive.on('*.renameInterfaceGlobal'
  , (_, oldName, newName, value) ->
      if not existsInObj(({ variable }) -> variable is oldName)(@get('widgetObj'))
        world.observer.setGlobal(oldName, undefined)
      world.observer.setGlobal(newName, value)
      false
  )

  ractive.on('*.refresh-chooser', (_, chooser) ->
    chooser.currentChoice = Math.max(0, chooser.choices.findIndex(eq(chooser.currentValue)))
    chooser.currentValue  = chooser.choices[chooser.currentChoice]
    world.observer.setGlobal(chooser.variable, chooser.currentValue)
    false
  )

  ractive.on('*.update-topology'
  , ->
      { wrappingallowedinx: wrapX, wrappingallowediny: wrapY } = viewController.model.world
      world.changeTopology(wrapX, wrapY)
  )

  setPatchSize = (patchSize) ->
    viewModel.dimensions.patchSize = patchSize
    viewModel.proxies.patchSize    = patchSize
    world.setPatchSize(patchSize)
    return

  ractive.on('*.resize-view'
  , ->
      { minpxcor, maxpxcor, minpycor, maxpycor, patchsize } = viewController.model.world
      setPatchSize(patchsize)
      world.resize(minpxcor, maxpxcor, minpycor, maxpycor)
  )

  ractive.on('*.set-patch-size', (_, patchSize) -> setPatchSize(patchSize))

  controller = new WidgetController(ractive, model, viewController, plotOps, mouse
                                  , write, output, dialog, worldConfig, importExport)

  ractive.on('*.redraw-view'
  , ->
      controller.redraw()
      viewController.repaint()
  )

  ractive.on('*.updateWidgets', -> controller.updateWidgets())

  ractive.on('*.unregisterWidget', (_, id) -> controller.removeWidgetById(id))

  ractive.on('createWidget'
  , (_, widgetType, pageX, pageY) ->
      controller.createWidget(widgetType, pageX, pageY)
  )

  setupInterfaceEditor(ractive)

  controller

showErrors = (errors) ->
  if errors.length > 0
    if window.nlwAlerter?
      window.nlwAlerter.displayError(errors.join('<br/>'))
    else
      alert(errors.join('\n'))

# [T] @ (() => T) => () => T
window.handlingErrors = (f) -> ->
  try f()
  catch ex
    if not (ex instanceof Exception.HaltInterrupt)
      message =
        if not (ex instanceof TypeError)
          ex.message
        else
          """A type error has occurred in the simulation engine.
             More information about these sorts of errors can be found
             <a href="https://netlogoweb.org/info#type-errors">here</a>.<br><br>
             Advanced users might find the generated error helpful, which is as follows:<br><br>
             <b>#{ex.message}</b><br><br>
             """
      showErrors([message])
      throw new Exception.HaltInterrupt
    else
      throw ex

class window.WidgetController

  constructor: (@ractive, @model, @viewController, @plotOps
              , @mouse, @write, @output, @dialog, @worldConfig, @importExport) ->

    for display, chartOps of @plotOps
      component = @ractive.findAllComponents("plotWidget").find((plot) -> plot.get("widget").display is display)
      component.set('resizeCallback', chartOps.resizeElem.bind(chartOps))

  # (String, Number, Number) => Unit
  createWidget: (widgetType, x, y) ->

    rect      = document.querySelector('.netlogo-widget-container').getBoundingClientRect()
    adjustedX = Math.round(x - rect.x)
    adjustedY = Math.round(y - rect.y)
    base      = { left: adjustedX, top: adjustedY, type: widgetType }
    mixin     = defaultWidgetMixinFor(widgetType, adjustedX, adjustedY)
    widget    = Object.assign(base, mixin)

    id = Math.max(Object.keys(@ractive.get('widgetObj')).map(parseFloat)...) + 1
    fillOutWidget(widget, id, (=> @redraw(); @updateWidgets()))
    @ractive.get('widgetObj')[id] = widget
    @ractive.update('widgetObj')
    @ractive.findAllComponents("").find((c) -> c.get('widget') is widget).fire('initializeWidget')

    return

  # () -> Unit
  runForevers: ->
    for widget in @widgets()
      if widget.type == 'button' and widget.forever and widget.running
        widget.run()

  # () -> Unit
  updateWidgets: ->
    for _, chartOps of @plotOps
      chartOps.redraw()

    for widget in @widgets()
      if widget.currentValue?
        if widget.variable?
          widget.currentValue = world.observer.getGlobal(widget.variable)
        else if widget.reporter?
          try
            widget.currentValue = widget.reporter()
            value        = widget.currentValue
            isValidValue = value? and ((typeof(value) isnt "number") or isFinite(value))
            if not isValidValue
              widget.currentValue = 'N/A'
          catch err
            widget.currentValue = 'N/A'
        if widget.precision? and typeof widget.currentValue == 'number' and isFinite(widget.currentValue)
          widget.currentValue = NLMath.precision(widget.currentValue, widget.precision)
      if widget['type'] == 'inputBox'
        widget.boxedValue.value = widget.currentValue
      if widget['type'] == 'slider'
        # Soooooo apparently range inputs don't visually update when you set
        # their max, but they DO update when you set their min (and will take
        # new max values into account)... Ractive ignores sets when you give it
        # the same value, so we have to tweak it slightly and then set it back.
        # Consequently, we can't rely on ractive's detection of value changes
        # so we'll end up thrashing the DOM.
        # BCH 10/23/2014
        maxValue  = widget.getMax()
        stepValue = widget.getStep()
        minValue  = widget.getMin()
        if widget.maxValue != maxValue or widget.stepValue != stepValue or widget.minValue != minValue
          widget.maxValue  = maxValue
          widget.stepValue = stepValue
          widget.minValue  = minValue - 0.000001
          widget.minValue  = minValue
      if widget['type'] == 'view'
        { maxPxcor, maxPycor, minPxcor, minPycor, patchSize } = widget.dimensions
        desiredWidth  = Math.round(patchSize * (maxPxcor - minPxcor + 1))
        desiredHeight = Math.round(patchSize * (maxPycor - minPycor + 1))
        widget.right  = widget.left + desiredWidth
        widget.bottom = widget.top  + desiredHeight

    if world.ticker.ticksAreStarted()
      @model.ticks = Math.floor(world.ticker.tickCount())
      @model.ticksStarted = true
    else
      @model.ticks = ''
      @model.ticksStarted = false

    @ractive.update()

  # (Number) => Unit
  removeWidgetById: (id) ->
    delete @ractive.get('widgetObj')[id]
    @ractive.update('widgetObj')
    @ractive.fire('deselectWidgets')
    return

  # () => Array[Widget]
  widgets: ->
    v for _, v of @ractive.get('widgetObj')

  # (Array[Widget], Array[Widget]) => Unit
  freshenUpWidgets: (realWidgets, newWidgets) ->

    for newWidget, index in newWidgets

      [matcher, setterUpper] =
        switch newWidget.type
          when "button"   then [  buttonEquals, setUpButton(=> @redraw(); @updateWidgets())]
          when "chooser"  then [ chooserEquals, setUpChooser]
          when "inputBox" then [inputBoxEquals, setUpInputBox]
          when "monitor"  then [ monitorEquals, setUpMonitor]
          when "output"   then [  outputEquals, (->)]
          when "plot"     then [    plotEquals, (->)]
          when "slider"   then [  sliderEquals, setUpSlider]
          when "switch"   then [  switchEquals, setUpSwitch]
          when "textBox"  then [ textBoxEquals, (->)]
          when "view"     then [    viewEquals, (->)]
          else                 throw new Error("Unknown widget type: #{newWidget.type}")

      realWidget = realWidgets.find(matcher(newWidget))

      if realWidget?

        realWidget.compilation = newWidget.compilation

        setterUpper(newWidget, realWidget)

        if newWidget.variable?
          realWidget.variable = newWidget.variable.toLowerCase()

        # This can go away when `res.model.result` stops blowing away all of the globals
        # on recompile/when the world state is preserved across recompiles.  --JAB (6/9/16)
        if newWidget.type in ["chooser", "inputBox", "slider", "switch"]
          world.observer.setGlobal(newWidget.variable, realWidget.currentValue)

    @updateWidgets()

    return

  # () -> number
  speed: -> @model.speed

  # (String) => Unit
  setCode: (code) ->
    @ractive.set('code', code)
    @ractive.findComponent('editor').setCode(code)
    @ractive.fire('controller.recompile')
    return

  # () -> Unit
  redraw: () ->
    if Updater.hasUpdates() then @viewController.update(Updater.collectUpdates())

  # () -> Unit
  teardown: -> @ractive.teardown()

  code: -> @ractive.get('code')

# [T <: Widget] @ Array[String] -> T -> T -> Boolean
compareWidgetsOn = (props) -> (w1) -> (w2) ->
  locationProps = ['bottom', 'left', 'right', 'top']
  w1.type is w2.type and locationProps.concat(props).every((prop) -> eq(w1[prop])(w2[prop]))

# Button -> Button -> Boolean
buttonEquals = compareWidgetsOn(['buttonKind', 'disableUntilTicksStart', 'forever', 'source'])

# Chooser -> Chooser -> Boolean
chooserEquals = compareWidgetsOn(['choices', 'display', 'variable'])

# InputBox -> InputBox -> Boolean
inputBoxEquals = compareWidgetsOn(['boxedValue', 'variable'])

# Monitor -> Monitor -> Boolean
monitorEquals = compareWidgetsOn(['display', 'fontSize', 'precision', 'source'])

# Output -> Output -> Boolean
outputEquals = compareWidgetsOn(['fontSize'])

# Plot -> Plot -> Boolean
plotEquals = compareWidgetsOn(['autoPlotOn', 'display', 'legendOn', 'pens', 'setupCode', 'updateCode'
                             , 'xAxis', 'xmax', 'xmin', 'yAxis', 'ymax', 'ymin'])

# Slider -> Slider -> Boolean
sliderEquals = compareWidgetsOn(['default', 'direction', 'display', 'max', 'min', 'step', 'units', 'variable'])

# Switch -> Switch -> Boolean
switchEquals = compareWidgetsOn(['display', 'on', 'variable'])

# TextBox -> TextBox -> Boolean
textBoxEquals = compareWidgetsOn(['color', 'display', 'fontSize', 'transparent'])

# View -> View -> Boolean
viewEquals = compareWidgetsOn(['dimensions', 'fontSize', 'frameRate'
                             , 'showTickCounter', 'tickCounterLabel', 'updateMode'])

reporterOf = (str) -> new Function("return #{str}")

# coffeelint: disable=max_line_length
# (String, Number, Number) => Unit
defaultWidgetMixinFor = (widgetType, x, y) ->
  switch widgetType
    when "output"   then { bottom: y + 60, right: x + 180, fontSize: 12 }
    when "switch"   then { bottom: y + 33, right: x + 100, on: false, variable: "" }
    when "slider"   then { bottom: y + 33, right: x + 170, default: 50, direction: "horizontal", max: "100", min: "0", step: "1", }
    when "inputBox" then { bottom: y + 60, right: x + 180, boxedValue: { multiline: false, type: "String", value: "" }, variable: "" }
    when "button"   then { bottom: y + 60, right: x + 180, buttonKind: "Observer", disableUntilTicksStart: false, forever: false, running: false }
    when "chooser"  then { bottom: y + 45, right: x + 140, choices: [], currentChoice: -1, variable: "" }
    when "monitor"  then { bottom: y + 45, right: x +  70, fontSize: 11, precision: 17 }
    when "plot"     then { bottom: y + 60, right: x + 180 }
    when "textBox"  then { bottom: y + 60, right: x + 180, color: 0, display: "", fontSize: 12, transparent: true }
    else throw new Error("Huh?  What kind of widget is a #{widgetType}?")
# coffeelint: enable=max_line_length

# ([widget], () -> Unit) -> Unit
# Destructive - Adds everything for maintaining state to the widget models,
# such `currentValue`s and actual functions for buttons instead of just code.
fillOutWidgets = (widgets, updateUICallback) ->
  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  for widget, id in widgets
    fillOutWidget(widget, id, updateUICallback)
  return

fillOutWidget = (widget, id, updateUICallback) ->
  widget.id = id
  if widget.variable?
    # Convert from NetLogo variables to Tortoise variables.
    widget.variable = widget.variable.toLowerCase()
  switch widget['type']
    when "switch"
      setUpSwitch(widget, widget)
    when "slider"
      widget.currentValue = widget.default
      setUpSlider(widget, widget)
    when "inputBox"
      setUpInputBox(widget, widget)
    when "button"
      setUpButton(updateUICallback)(widget, widget)
    when "chooser"
      setUpChooser(widget, widget)
    when "monitor"
      setUpMonitor(widget, widget)
  return

# (InputBox, InputBox) => Unit
setUpInputBox = (source, destination) ->
  destination.boxedValue   = source.boxedValue
  destination.currentValue = destination.boxedValue.value
  destination.variable     = source.variable
  destination.display      = destination.variable
  return

# (Switch, Switch) => Unit
setUpSwitch = (source, destination) ->
  destination.on           = source.on
  destination.currentValue = destination.on
  return

# (Chooser, Chooser) => Unit
setUpChooser = (source, destination) ->
  destination.choices       = source.choices
  destination.currentChoice = source.currentChoice
  destination.currentValue  = destination.choices[destination.currentChoice]
  return

# (() => Unit) => (Button, Button) => Unit
setUpButton = (updateUI) -> (source, destination) ->
  if source.forever then destination.running = false
  if source.compilation?.success
    destination.compiledSource = source.compiledSource
    task = window.handlingErrors(new Function(destination.compiledSource))
    do (task) ->
      wrappedTask =
        if source.forever
          () ->
            mustStop =
              try task() instanceof Exception.StopInterrupt
              catch ex
                ex instanceof Exception.HaltInterrupt
            if mustStop
              destination.running = false
              updateUI()
        else
          () ->
            task()
            updateUI()
      do (wrappedTask) ->
        destination.run = wrappedTask
  else
    destination.run =
      ->
        destination.running = false
        showErrors(["Button failed to compile with:"].concat(source.compilation?.messages ? []))
  return

# (Monitor, Monitor) => Unit
setUpMonitor = (source, destination) ->
  if source.compilation?.success
    destination.compiledSource = source.compiledSource
    destination.reporter       = reporterOf(destination.compiledSource)
    destination.currentValue   = ""
  else
    destination.reporter     = () -> "N/A"
    destination.currentValue = "N/A"
  return

# (Slider, Slider) => Unit
setUpSlider = (source, destination) ->
  destination.default      = source.default
  destination.compiledMin  = source.compiledMin
  destination.compiledMax  = source.compiledMax
  destination.compiledStep = source.compiledStep
  if source.compilation?.success
    destination.getMin  = reporterOf(destination.compiledMin)
    destination.getMax  = reporterOf(destination.compiledMax)
    destination.getStep = reporterOf(destination.compiledStep)
  else
    destination.getMin  = () -> destination.currentValue
    destination.getMax  = () -> destination.currentValue
    destination.getStep = () -> 0
  destination.minValue     = destination.currentValue
  destination.maxValue     = destination.currentValue + 1
  destination.stepValue    = 1
  return

# (Widgets.View.Dimensions, AgentStreamController.View) -> Unit
setUpDimensionsProxies = (viewWidget, modelView) ->

  translations = {
    maxPxcor:           "maxpxcor"
  , maxPycor:           "maxpycor"
  , minPxcor:           "minpxcor"
  , minPycor:           "minpycor"
  , patchSize:          "patchsize"
  , wrappingAllowedInX: "wrappingallowedinx"
  , wrappingAllowedInY: "wrappingallowediny"
  }

  viewWidget.proxies = {}

  for wName, mName of translations
    addProxyTo(viewWidget.proxies, [[viewWidget.dimensions, wName], [modelView, mName]]
             , wName, viewWidget.dimensions[wName])

  return

# (Element, [widget]) -> [HighchartsOps]
# Creates the plot ops for Highchart interaction.
createPlotOps = (container, widgets) ->
  plotOps = {}
  for { display, id, type } in widgets when type is "plot"
    plotOps[display] = new HighchartsOps(container.querySelector("#netlogo-plot-#{id}"))
  plotOps

# (widget, Any) -> Boolean
isValidValue = (widget, value) ->
  value? and
    switch widget.type
      when 'slider'   then not isNaN(value)
      when 'inputBox' then not (widget.boxedValue.type == 'Number' and isNaN(value))
      else  true

# coffeelint: disable=max_line_length
template =
  """
  <div class="netlogo-model" style="min-width: {{width}}px;"
       tabindex="1" on-keydown="@this.fire('checkActionKeys', @event)"
       on-focus="@this.fire('checkFocus', @node)"
       on-blur="@this.fire('checkFocus', @node)">
    <div class="netlogo-header">
      <div class="netlogo-subheader">
        <div class="netlogo-powered-by">
          <a href="http://ccl.northwestern.edu/netlogo/">
            <img style="vertical-align: middle;" alt="NetLogo" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAANcSURBVHjarJRdaFxFFMd/M/dj7252uxubKms+bGprVyIVbNMWWqkQqtLUSpQWfSiV+oVFTcE3DeiDgvoiUSiCYLH2oVoLtQ+iaaIWWtE2FKGkkSrkq5svN+sm7ma/7p3x4W42lEbjQw8MM8yc87/nzPnNFVprbqWJXyMyXuMqx1Ni6N3ny3cX8tOHNLoBUMvESoFI2Xbs4zeO1lzREpSrMSNS1zkBDv6uo1/noz1H7mpvS4SjprAl2AZYEqzKbEowBAgBAkjPKX2599JjT7R0bj412D0JYNplPSBD1G2SmR/e6u1ikEHG2vYiGxoJmxAyIGSCI8GpCItKimtvl2JtfGujDNkX6epuAhCjNeAZxM1ocPy2Qh4toGQ5DLU+ysiuA2S3P0KgJkjAgEAlQylAA64CG/jlUk6//ng4cNWmLK0yOPNMnG99Rs9LQINVKrD+wmke7upg55PrWP3eYcwrlykpKCkoelDy/HVegQhoABNAepbACwjOt72gZkJhypX70YDWEEklue+rbnYc2MiGp1upPfYReiJJUUG58gFXu4udch1wHcjFIgy0HyIjb2yvBpT2F6t+6+f+D15lW8c9JDo7iPSdgVIRLUqL2AyHDQAOf9hfbqxvMF98eT3RuTS1avHyl+Stcphe2chP9+4k/t3RbXVl3W+Ws17FY56/w3VcbO/koS/eZLoAqrQMxADZMTYOfwpwoWjL4+bCYcgssMqGOzPD6CIkZ/3SxTJ0ayFIN6/BnBrZb2XdE1JUgkJWkfrUNRJnPyc16zsbgPyXIUJBpvc+y89nk/S8/4nek3NPGeBWMwzGvhUPnP6RubRLwfODlqqx3LSCyee2MnlwMwA2RwgO5qouVcHmksUdJweYyi8hZkrUjgT5t/ejNq0jBsSqNWsKyT9uFtxw7Bs585d3g46KOeT2bWHmtd14KyP+5mzqpsYU3OyioACMhGiqPTMocsrHId9cy9BLDzKxq8X3ctMwlV6yKSHL4fr4dd0DeQBTBUgUkvpE1kVPbqkX117ZzuSaFf4zyfz5n9A4lk0yNU7vyb7jTy1kmFGipejKvh6h9n0W995ZPTu227hqmCz33xXgFV1v9NzI96NfjndWt7XWCB/7BSICFWL+j3lAofpCtfYFb6X9MwCJZ07mUsXRGwAAAABJRU5ErkJggg=="/>
            <span style="font-size: 16px;">powered by NetLogo</span>
          </a>
        </div>
      </div>
      <editableTitle title="{{modelTitle}}" isEditing="{{isEditing}}"/>
      {{# !readOnly }}
        <div class="flex-column" style="align-items: flex-end; user-select: none;">
          <div class="netlogo-export-wrapper">
            <span style="margin-right: 4px;">File:</span>
            <button class="netlogo-ugly-button" on-click="openNewFile">New</button>
          </div>
          <div class="netlogo-export-wrapper">
            <span style="margin-right: 4px;">Export:</span>
            <button class="netlogo-ugly-button" on-click="exportnlogo">NetLogo</button>
            <button class="netlogo-ugly-button" on-click="exportHtml">HTML</button>
          </div>
        </div>
      {{/}}
    </div>

    <div class="netlogo-interface-unlocker" style="display: none" class="{{#isEditing}}interface-unlocked{{/}}" on-click="toggleInterfaceLock"></div>

    <contextMenu></contextMenu>

    <label class="netlogo-widget netlogo-speed-slider{{#isEditing}} interface-unlocked{{/}}">
      <span class="netlogo-label">model speed</span>
      <input type="range" min=-1 max=1 step=0.01 value="{{speed}}"{{#isEditing}} disabled{{/}} />
      <tickCounter isVisible="{{primaryView.showTickCounter}}"
                   label="{{primaryView.tickCounterLabel}}" value="{{ticks}}" />
    </label>

    <div style="position: relative; width: {{width}}px; height: {{height}}px"
         class="netlogo-widget-container"
         on-contextmenu="@this.fire('showContextMenu', { component: @this }, @event)"
         on-click="@this.fire('deselectWidgets', @event)">
      <resizer isEnabled="{{isEditing}}" />
      {{#widgetObj:key}}
        {{# type === 'view'     }} <viewWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} ticks="{{ticks}}" /> {{/}}
        {{# type === 'textBox'  }} <labelWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} /> {{/}}
        {{# type === 'switch'   }} <switchWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} /> {{/}}
        {{# type === 'button'   }} <buttonWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} errorClass="{{>errorClass}}" ticksStarted="{{ticksStarted}}"/> {{/}}
        {{# type === 'slider'   }} <sliderWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} errorClass="{{>errorClass}}" /> {{/}}
        {{# type === 'chooser'  }} <chooserWidget id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} /> {{/}}
        {{# type === 'monitor'  }} <monitorWidget id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} errorClass="{{>errorClass}}" /> {{/}}
        {{# type === 'inputBox' }} <inputWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} /> {{/}}
        {{# type === 'plot'     }} <plotWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} /> {{/}}
        {{# type === 'output'   }} <outputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} text="{{outputWidgetOutput}}" /> {{/}}
      {{/}}
    </div>

    <div class="netlogo-tab-area" style="max-width: {{Math.max(width, 500)}}px">
      {{# !readOnly }}
      <label class="netlogo-tab{{#showConsole}} netlogo-active{{/}}">
        <input id="console-toggle" type="checkbox" checked="{{showConsole}}" />
        <span class="netlogo-tab-text">Command Center</span>
      </label>
      {{#showConsole}}
        <console output="{{consoleOutput}}" isEditing="{{isEditing}}"/>
      {{/}}
      {{/}}
      <label class="netlogo-tab{{#showCode}} netlogo-active{{/}}">
        <input id="code-tab-toggle" type="checkbox" checked="{{ showCode }}" />
        <span class="netlogo-tab-text{{#lastCompileFailed}} netlogo-widget-error{{/}}">NetLogo Code</span>
      </label>
      {{#showCode}}
        <editor code='{{code}}' lastCompiledCode='{{lastCompiledCode}}' readOnly='{{readOnly}}' />
      {{/}}
      <label class="netlogo-tab{{#showInfo}} netlogo-active{{/}}">
        <input id="info-toggle" type="checkbox" checked="{{ showInfo }}" />
        <span class="netlogo-tab-text">Model Info</span>
      </label>
      {{#showInfo}}
        <infotab rawText='{{info}}' editing='false' />
      {{/}}
    </div>
  </div>
  """

partials = {

  errorClass:
    """
    {{# !compilation.success}}netlogo-widget-error{{/}}
    """

  widgetID:
    """
    netlogo-{{type}}-{{id}}
    """

}
# coffeelint: enable=max_line_length
