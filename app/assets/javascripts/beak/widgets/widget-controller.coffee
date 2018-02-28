class window.WidgetController

  # (Ractive, ViewController, Configs)
  constructor: (@ractive, @viewController, @configs) ->

    for display, chartOps of @configs.plotOps
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
    window.setUpWidget(widget, id, (=> @redraw(); @updateWidgets()))
    @ractive.get('widgetObj')[id] = widget
    @ractive.update('widgetObj')
    @ractive.findAllComponents("").find((c) -> c.get('widget') is widget).fire('initialize-widget')

    return

  # () => Unit
  runForevers: ->
    for widget in @widgets()
      if widget.type == 'button' and widget.forever and widget.running
        widget.run()
    return

  # () => Unit
  updateWidgets: ->

    for _, chartOps of @configs.plotOps
      chartOps.redraw()

    for widget in @widgets()
      updateWidget(widget)

    if world.ticker.ticksAreStarted()
      @ractive.set('ticks'       , Math.floor(world.ticker.tickCount()))
      @ractive.set('ticksStarted', true)
    else
      @ractive.set('ticks'       , '')
      @ractive.set('ticksStarted', false)

    @ractive.update()

    return

  # (Number, Boolean) => Unit
  removeWidgetById: (id, widgetWasNew = false) ->

    widgetType = @ractive.get('widgetObj')[id].type

    delete @ractive.get('widgetObj')[id]
    @ractive.update('widgetObj')
    @ractive.fire('deselect-widgets')

    if not widgetWasNew
      switch widgetType
        when "chooser", "inputBox", "plot", "slider", "switch" then @ractive.fire('controller.recompile')

    return

  # () => Array[Widget]
  widgets: ->
    v for _, v of @ractive.get('widgetObj')

  # (Array[Widget], Array[Widget]) => Unit
  freshenUpWidgets: (realWidgets, newWidgets) ->

    for newWidget, index in newWidgets

      [props, setterUpper] =
        switch newWidget.type
          when "button"   then [  buttonProps, window.setUpButton(=> @redraw(); @updateWidgets())]
          when "chooser"  then [ chooserProps, window.setUpChooser]
          when "inputBox" then [inputBoxProps, window.setUpInputBox]
          when "monitor"  then [ monitorProps, window.setUpMonitor]
          when "output"   then [  outputProps, (->)]
          when "plot"     then [    plotProps, (->)]
          when "slider"   then [  sliderProps, window.setUpSlider]
          when "switch"   then [  switchProps, window.setUpSwitch]
          when "textBox"  then [ textBoxProps, (->)]
          when "view"     then [    viewProps, (->)]
          else                 throw new Error("Unknown widget type: #{newWidget.type}")

      realWidget = realWidgets.find(widgetEqualsBy(props)(newWidget))

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

  # () => Number
  speed: ->
    @ractive.get('speed')

  # (String) => Unit
  setCode: (code) ->
    @ractive.set('code', code)
    @ractive.findComponent('editor').setCode(code)
    @ractive.fire('controller.recompile')
    return

  # () => Unit
  redraw: ->
    if Updater.hasUpdates() then @viewController.update(Updater.collectUpdates())
    return

  # () => Unit
  teardown: ->
    @ractive.teardown()
    return

  # () => String
  code: ->
    @ractive.get('code')

# (Widget) => Unit
updateWidget = (widget) ->

  if widget.currentValue?
    widget.currentValue =
      if widget.variable?
        world.observer.getGlobal(widget.variable)
      else if widget.reporter?
        try
          value = widget.reporter()
          isntValidValue = not (value? and ((typeof(value) isnt "number") or isFinite(value)))
          if isntValidValue
            'N/A'
          else
            if precision?
              NLMath.precision(value, widget.precision)
            else
              value
        catch err
          'N/A'
      else
        widget.currentValue

  switch widget.type

    when 'inputBox'
      widget.boxedValue.value = widget.currentValue

    when 'slider'
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

    when 'view'
      { maxPxcor, maxPycor, minPxcor, minPycor, patchSize } = widget.dimensions
      desiredWidth  = Math.round(patchSize * (maxPxcor - minPxcor + 1))
      desiredHeight = Math.round(patchSize * (maxPycor - minPycor + 1))
      widget.right  = widget.left + desiredWidth
      widget.bottom = widget.top  + desiredHeight

  return

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

# [T <: Widget] @ Array[String] => T => T => Boolean
widgetEqualsBy = (props) -> (w1) -> (w2) ->
  { eq } = tortoise_require('brazier/equals')
  locationProps = ['bottom', 'left', 'right', 'top']
  w1.type is w2.type and locationProps.concat(props).every((prop) -> eq(w1[prop])(w2[prop]))

buttonProps   = ['buttonKind', 'disableUntilTicksStart', 'forever', 'source']
chooserProps  = ['choices', 'display', 'variable']
inputBoxProps = ['boxedValue', 'variable']
monitorProps  = ['display', 'fontSize', 'precision', 'source']
outputProps   = ['fontSize']
plotProps     = [ 'autoPlotOn', 'display', 'legendOn', 'pens', 'setupCode', 'updateCode', 'xAxis', 'xmax', 'xmin', 'yAxis', 'ymax', 'ymin']
sliderProps   = ['default', 'direction', 'display', 'max', 'min', 'step', 'units', 'variable']
switchProps   = ['display', 'on', 'variable']
textBoxProps  = ['color', 'display', 'fontSize', 'transparent']
viewProps     = ['dimensions', 'fontSize', 'frameRate', 'showTickCounter', 'tickCounterLabel', 'updateMode']
# coffeelint: enable=max_line_length
