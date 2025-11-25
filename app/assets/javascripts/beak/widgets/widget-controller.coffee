import { setUpWidget, setUpButton, setUpChooser, setUpInputBox
       , setUpMonitor, setUpPlot, setUpSlider, setUpSwitch
       , setUpHNWButton, setUpHNWChooser, setUpHNWInputBox
       , setUpHNWMonitor, setUpHNWPlot, setUpHNWSlider, setUpHNWSwitch
       } from "./set-up-widgets.js"

import { VIEW_INNER_SPACING } from "./ractives/view.js"
import { locationProperties, typedWidgetProperties } from "./widget-properties.js"

import { prepareColorPickerForInline } from "./ractives/subcomponent/color-picker.js"
import CodeUtils from "./code-utils.js"

PenBundle = tortoise_require('engine/plot/pen')

class WidgetController

  # (Ractive, ViewController, Configs, () => Unit)
  constructor: (@ractive, @viewController, @configs, @_performUpdate) ->
    @ractive.observe('isEditing', (isEditing) =>
      color = if isEditing then '#efefef' else '#ffffff'
      Object.values(@configs.plotOps).forEach((pops) -> pops.setBGColor(color))
    )

  # (String, Number, Number) => Unit
  createWidget: (widgetType, x, y) ->

    rect      = document.querySelector('.netlogo-widget-container').getBoundingClientRect()
    adjustedX = Math.round(x - (rect.left + window.scrollX ) )
    adjustedY = Math.round(y - (rect.top + window.scrollY) )
    base      = { x: adjustedX, y: adjustedY, type: widgetType, oldSize: false }
    mixin     = defaultWidgetMixinFor(widgetType, adjustedX, adjustedY, @_countByType)
    widget    = Object.assign(base, mixin)

    id = Math.max(Object.keys(@ractive.get('widgetObj')).map(parseFloat)...) + 1
    @ractive.get('widgetObj')[id] = widget
    @ractive.update('widgetObj')

    callback = (=> @_performUpdate(); @updateWidgets())
    setUpWidget(@reportError, widget, id, callback, @plotSetupHelper())

    if widget.variable? and widget.currentValue?
      world.observer.setGlobal(widget.variable, widget.currentValue)

    @ractive.findAllComponents("").find((c) -> c.get('widget') is widget).fire('initialize-widget')
    @ractive.fire('new-widget-initialized', id, widgetType)

    return

  # (Plot) => Number
  createPlot: (plot) ->

    id = Math.max(Object.keys(@ractive.get('widgetObj')).map(parseFloat)...) + 1
    @ractive.get('widgetObj')[id] = plot
    @ractive.update('widgetObj')

    callback = (=> @_performUpdate(); @updateWidgets())
    setUpWidget(@reportError, plot, id, callback, @plotSetupHelper())

    @ractive.findAllComponents("").find((c) -> c.get('widget') is plot).fire('initialize-widget')

    id

  # () => Unit
  runForevers: ->
    for widget in @widgets()
      if widget.forever and widget.running
        if widget.type is 'button'
          widget.run()
        else if widget.type is 'hnwButton'
          @ractive.fire('hnw-send-widget-message', 'button', widget.hnwProcName)

    return

  # () => Unit
  pauseForevers: () ->
    if not @runningIndices? or @runningIndices.length is 0
      widgets = @ractive.get('widgetObj')

      @runningIndices = Object.getOwnPropertyNames(widgets)
        .filter( (index) ->
          widget = widgets[index]
          widget.type is "button" and widget.forever and widget.running
        )
      @runningIndices.forEach( (index) -> widgets[index].running = false )
    return

  # () => Unit
  rerunForevers: () =>
    if @runningIndices? and @runningIndices.length > 0
      widgets = @ractive.get('widgetObj')

      @runningIndices.forEach( (index) -> widgets[index].running = true )
    @runningIndices = []
    return

  # () => Unit
  updateWidgets: ->

    isHNWClient = @ractive.get('isHNW') and not @ractive.get('isHNWHost')

    if not @ractive.get('isHNWHost')
      for _, chartOps of @configs.plotOps
        chartOps.redraw()
        color = if @ractive.get('isEditing') then '#efefef' else '#ffffff'
        chartOps.setBGColor(color)

    for widget in @widgets()
      updateWidget(widget, isHNWClient)

    if world.ticker.ticksAreStarted()
      @ractive.set('ticks'       , Math.floor(world.ticker.tickCount()))
      @ractive.set('ticksStarted', true)
    else
      @ractive.set('ticks'       , '')
      @ractive.set('ticksStarted', false)

    @ractive.update()

    return

  # (Number, Boolean, Array[Any]) => Unit
  removeWidgetById: (id, wasNew, extraNotificationArgs) ->

    wobj = @ractive.get('widgetObj')

    entry = Object.entries(wobj).find(([_, v]) -> v.id is id)

    if entry?

      [index, widget] = entry

      widgetType = widget.type
      delete wobj[index]

      @ractive.update('widgetObj')
      @ractive.fire('deselect-widgets')

      if wasNew
        @ractive.fire('new-widget-cancelled', id, widgetType)

      else
        switch widgetType
          when "chooser", "inputBox", "plot", "slider", "switch" then @ractive.fire('recompile-sync', 'system')
        @ractive.fire('widget-deleted', id, widgetType, extraNotificationArgs...)

    else
      throw new Error("Failed to find any widget in #{JSON.stringify(wobj)} with ID '#{id}'.")

    return

  # () => Array[Widget]
  widgets: ->
    v for _, v of @ractive.get('widgetObj')

  # () => void
  onBeforeExportHTMLFetch: ->
    await prepareColorPickerForInline()

  # (Document) => void
  onBeforeExportHTMLDocument: (document) ->
    CodeUtils.dataTagStore.copyAllToDocument(document)
    return

  # ("runtime" | "compiler", String, Exception | Array[String])
  reportError: (time, source, details, ...args) =>
    switch time
      when "compiler" then @ractive.fire("compiler-error", {}, source, "", "", details, ...args)
      when "runtime"  then @ractive.fire( "runtime-error", {}, source        , details, ...args)
      else                 throw new Error('Only valid values for `time` are "runtime" or "compiler"')

  # (Array[Widget], Array[Widget]) => Unit
  freshenUpWidgets: (realWidgets, newWidgets) ->

    for newWidget, index in newWidgets

      newWidget.id = index

      hnwTypePrefix = "hnw"
      propsType =
        if not newWidget.type.startsWith(hnwTypePrefix)
          newWidget.type
        else
          s = newWidget.type
          l = hnwTypePrefix.length
          "#{s[l].toLowerCase()}#{s.slice(l + 1)}"

      props       = typedWidgetProperties.get(propsType)
      setterUpper =
        switch newWidget.type
          when "button"      then setUpButton(@reportError, () => @_performUpdate(); @updateWidgets())
          when "chooser"     then setUpChooser
          when "inputBox"    then setUpInputBox
          when "monitor"     then setUpMonitor
          when "output"      then (->)
          when "plot"        then setUpPlot(@plotSetupHelper())
          when "slider"      then setUpSlider
          when "switch"      then setUpSwitch
          when "textBox"     then (->)
          when "view"        then (->)

          when "hnwButton"   then setUpHNWButton(=> @_performUpdate(); @updateWidgets())
          when "hnwChooser"  then setUpHNWChooser
          when "hnwInputBox" then setUpHNWInputBox
          when "hnwMonitor"  then setUpHNWMonitor
          when "hnwOutput"   then (->)
          when "hnwPlot"     then setUpHNWPlot(@plotSetupHelper())
          when "hnwSlider"   then setUpHNWSlider
          when "hnwSwitch"   then setUpHNWSwitch
          when "hnwTextBox"  then (->)
          when "hnwView"     then (->)

          else                    throw new Error("Unknown widget type: #{newWidget.type}")

      realWidget = realWidgets.find(widgetEqualsBy(props)(newWidget))

      if realWidget?

        realWidget.compilation = newWidget.compilation

        setterUpper(newWidget, realWidget)

        if newWidget.variable?
          realWidget.variable = newWidget.variable.toLowerCase()

        # This can go away when `res.model.result` stops blowing away all of the globals
        # on recompile/when the world state is preserved across recompiles.
        # --Jason B. (6/9/16)
        types =
          [    "chooser",    "inputBox",    "slider",    "switch"
          , "hnwChooser", "hnwInputBox", "hnwSlider", "hnwSwitch"
          ]

        if newWidget.type in types
          world.observer.setGlobal(newWidget.variable, realWidget.currentValue)

    @updateWidgets()

    return

  # () => Number
  speed: ->
    @ractive.get('speed')

  # (String, Boolean) => Unit
  setCode: (code, recompile = true) =>
    @ractive.set('code', code)
    @ractive.findComponent('codePane')?.setCode(code)
    if recompile then @ractive.fire('recompile', 'system')
    return

  # (String) => Unit
  jumpToProcedure: (procName) ->
    @ractive.set('showCode', true)
    @ractive.findComponent('codePane').set('jumpToProcedure', procName)
    codeTab = @ractive.find('#netlogo-code-tab')
    if codeTab?
      # Something during the widget updates resets the scroll position if we do it directly.
      # So just wait a split sec and then scroll.  -Jeremy B March 2021
      scrollMe = () -> codeTab.scrollIntoView()
      window.setTimeout(scrollMe, 50)
    return

  # (Int, Int) => Unit
  jumpToCode: (start, end) ->
    @ractive.set('showCode', true)
    @ractive.findComponent('codePane').set('jumpToCode', { start, end })
    codeTab = @ractive.find('#netlogo-code-tab')
    if codeTab?
      # Something during the widget updates resets the scroll position if we do it directly.
      # So just wait a split sec and then scroll.  -Jeremy B March 2021
      scrollMe = () -> codeTab.scrollIntoView()
      window.setTimeout(scrollMe, 50)
    return

  # (Array[Update]) => Unit
  redraw: (updates) ->
    @viewController.update(updates)
    return

  # () => Unit
  teardown: ->
    if not @ractive.torndown
      @ractive.teardown()
    return

  # () => String
  code: ->
    @ractive.get('code')

  # (String) => Unit
  appendOutput: (output) ->
    widget = [].concat( @ractive.findAllComponents("outputWidget")
                      , @ractive.findAllComponents("hnwOutputWidget"))[0]
    widget?.appendText(output)
    return

  # (String) => Unit
  setOutput: (output) ->
    widget = [].concat( @ractive.findAllComponents("outputWidget")
                      , @ractive.findAllComponents("hnwOutputWidget"))[0]
    widget?.setText(output)
    return

  # (String) => PlotHelper
  plotSetupHelper: ->
    {
      getPlotComps: ()  => [].concat( @ractive.findAllComponents("plotWidget")
                                    , @ractive.findAllComponents("hnwPlotWidget"))
      getPlotOps:   ()  => @configs.plotOps
      lookupElem:   (s) => @ractive.find(s)
    }

  # () => Number
  getFPS: ->
    @widgets().find((w) -> w.type is 'view' or w.type is 'hnwView')?.frameRate ? 30

  # () => Object[Array[PlotEvent]]
  getPlotInits: ->
    out = {}
    for display, chartOps of @configs.plotOps
      out[display] = chartOps.cloneInitializer()
    out

  # () => Object[Array[PlotEvent]]
  getPlotUpdates: ->
    out = {}
    for display, chartOps of @configs.plotOps
      out[display] = chartOps.pullPlotEvents()
    out

  # (Object[Number]) => Unit
  applyChooserUpdates: (update) ->

    for varName, value of (update ? {})

      index = value

      widget =
        @widgets().find(
          (w) ->
            w.type.endsWith("hooser") and
              w.variable.toLowerCase() is varName.toLowerCase()
        )

      widget.currentChoice = index

      trueValue =
        if index isnt -1
          widget.choices[index]
        else
          0

      world.observer.setGlobal(varName, trueValue)

    return

  # (Object[Number]) => Unit
  applyInputNumUpdates: (update) ->
    for varName, value of (update ? {})
      world.observer.setGlobal(varName, value)
    return

  # (Object[String]) => Unit
  applyInputStrUpdates: (update) ->
    for varName, value of (update ? {})
      world.observer.setGlobal(varName, value)
    return

  # (Object[Number]) => Unit
  applySliderUpdates: (update) ->
    for varName, value of (update ? {})
      world.observer.setGlobal(varName, value)
    return

  # (Object[Boolean]) => Unit
  applySwitchUpdates: (update) ->
    for varName, value of (update ? {})
      world.observer.setGlobal(varName, value)
    return

  # (Object[String]) => Unit
  applyMonitorUpdates: (update) ->

    matchHNWMon =
      (target) -> (w) ->
        w.type is "hnwMonitor" and w.source.toLowerCase() is target

    widgets = @widgets()

    for k, v of (update ? {})
      lowerName           = k.toLowerCase()
      widget              = widgets.find(matchHNWMon(lowerName))
      widget.reporter     = do (v) -> (-> v)
      widget.currentValue = v

    return

  # (Object[Array[PlotEvent]]) => Unit
  applyPlotUpdates: (updates) ->
    for plotDisplay, plotUpdates of (updates ? {})
      for update in plotUpdates ? []
        if @configs.plotOps?
          ops = @configs.plotOps[plotDisplay]
          if ops?
            switch update.type
              when "reset"
                ops.reset(update.plot)
              when "resize"
                ops.resize(update.xMin, update.xMax, update.yMin, update.yMax)
              when "register-pen"
                pen = { name:           update.pen.name
                      , getColor:       (-> update.pen.color)
                      , getDisplayMode: (-> PenBundle.DisplayMode.Line)
                      , getInterval:    (-> update.pen.interval)
                      , isFake:         true
                      }
                ops.registerPen(pen)
              when "reset-pen"
                ops.resetPen({ name: update.penName, isFake: true })()
              when "add-point"
                pen = { name: update.penName, isFake: true }
                ops.addPoint(pen)(update.x, update.y)
              when "update-pen-mode"
                pen  = { name: update.penName, isFake: true }
                mode =
                  switch update.mode.toLowerCase()
                    when "bar"   then PenBundle.DisplayMode.Bar
                    when "line"  then PenBundle.DisplayMode.Line
                    when "point" then PenBundle.DisplayMode.Point
                getInterval = (-> update.interval)
                pen         = { name: update.penName, getInterval, isFake: true }
                ops.updatePenMode(pen)(mode)
              when "update-pen-color"
                pen = { name: update.penName, isFake: true }
                ops.updatePenColor(pen)(update.color)

  # (String) => Number
  _countByType: (type) =>
    @widgets().filter((w) -> w.type is type).length

# (Widget, Boolean) => Unit
updateWidget = (widget, isHNWClient) ->

  if widget.currentValue?
    widget.currentValue =
      if widget.variable?
        world.observer.getGlobal(widget.variable)
      else if widget.reporter?
        try
          value = widget.reporter()
          isNum = (typeof(value) is "number")
          isString = (typeof(value) is "string") \
                      and (value.trim() isnt "") \
                      and (parseFloat(value).toString() isnt value)
          isntValidValue = not (value? and (not isNum or isFinite(value)))
          if isntValidValue
            'N/A'
          else if isString
            value
          else if isNum
            preci = widget.precision
            if preci?
              if not isHNWClient
                withPrecision(value, preci)
              else # In HNW, all Monitor values are strings --Jason B. (2/25/24)
                parsed = parseFloat(value)
                if Number.isNaN(parsed)
                  value
                else
                  withPrecision(parsed, preci)
            else
              value
          else
            workspace.dump(value, false)

        catch err
          'N/A'
      else
        widget.currentValue

  switch widget.type

    when 'inputBox', 'hnwInputBox'
      widget.boxedValue.value = widget.currentValue

    when 'slider', 'hnwSlider'
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
      if widget.maxValue isnt maxValue or widget.stepValue isnt stepValue or widget.minValue isnt minValue
        widget.maxValue  = maxValue
        widget.stepValue = stepValue
        widget.minValue  = minValue - 0.000001
        widget.minValue  = minValue

    when 'view'
      { maxPxcor, maxPycor, minPxcor, minPycor, patchSize } = widget.dimensions
      canvasWidth   = Math.round(patchSize * (maxPxcor - minPxcor + 1))
      canvasHeight  = Math.round(patchSize * (maxPycor - minPycor + 1))
      widget.width  = canvasWidth  + VIEW_INNER_SPACING.horizontal
      widget.height = canvasHeight + VIEW_INNER_SPACING.vertical

  return

# (Number, Number) => Number
withPrecision = (n, places) ->
  multiplier = Math.pow(10, places)
  result     = Math.floor(n * multiplier + 0.5) / multiplier
  if places > 0
    result
  else
    Math.round(result)

# coffeelint: disable=max_line_length
# (String, Number, Number, (String) => Number) => Unit
defaultWidgetMixinFor = (widgetType, x, y, countByType) ->
  switch widgetType
    when "output"  , "hnwOutput"   then { height:  60, width: 220, fontSize: 12 }
    when "switch"  , "hnwSwitch"   then { height:  40, width: 100, on: false, variable: "" }
    when "slider"  , "hnwSlider"   then { height:  50, width: 250, default: 50, direction: "horizontal", max: "100", min: "0", step: "1", }
    when "inputBox", "hnwInputBox" then { height:  60, width: 250, boxedValue: { multiline: false, type: "String", value: "" }, variable: "" }
    when "button"  , "hnwButton"   then { height:  50, width: 120, buttonKind: "Observer", disableUntilTicksStart: false, forever: false, running: false }
    when "chooser" , "hnwChooser"  then { height:  60, width: 250, choices: [], currentChoice: -1, variable: "" }
    when "monitor" , "hnwMonitor"  then { height:  60, width: 100, fontSize: 11, precision: 17 }
    when "plot"    , "hnwPlot"     then { height: 175, width: 230, autoPlotX: true, autoPlotY: true, display: "Plot #{countByType(widgetType) + 1}", legendOn: false, pens: [], setupCode: "", updateCode: "", xAxis: "", xmax: 10, xmin: 0, yAxis: "", ymax: 10, ymin: 0, exists: false }
    when "textBox" , "hnwTextBox"  then { height:  60, width: 180, backgroundLight: 0, textColorLight: -16777216, display: "", fontSize: 12, markdown: false }
    else throw new Error("Huh?  What kind of widget is a #{widgetType}?")
# coffeelint: enable=max_line_length

# [T <: Widget] @ Array[String] => T => T => Boolean
widgetEqualsBy = (props) -> (w1) -> (w2) ->
  { eq } = tortoise_require('brazier/equals')
  propEq = (prop) ->
    v1 = w1[prop]
    v2 = w2[prop]
    ((v1 is null or v1 is undefined) and (v2 is null or v2 is undefined)) or eq(v1)(v2)
  w1.type is w2.type and locationProperties.concat(props).every(propEq)

export default WidgetController
