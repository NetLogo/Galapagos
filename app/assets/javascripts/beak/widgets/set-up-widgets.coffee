import { hexStringToNetlogoColor } from "/colors.js"

import HighchartsOps from "/highcharts.js"

# ((String, Exception) => Unit, Array[Widget], () => Unit, PlotHelper) => Unit
setUpWidgets = (reportError, widgets, updateUI, plotSetupHelper) ->
  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  for widget, id in widgets
    setUpWidget(reportError, widget, id, updateUI, plotSetupHelper)

  return

reporterOf = (str) -> new Function("return #{str}")

# Destructive - Adds everything for maintaining state to the widget models,
# such `currentValue`s and actual functions for buttons instead of just code.
# ((String, String, Exception) => Unit, Widget, String, () => Unit, PlotHelper) => Unit
setUpWidget = (reportError, widget, id, updateUI, plotSetupHelper) ->
  widget.id = id
  if widget.variable?
    # Convert from NetLogo variables to Tortoise variables.
    widget.variable = widget.variable.toLowerCase()
  switch widget.type
    when "switch"
      setUpSwitch(widget, widget)
    when "slider"
      widget.currentValue = widget.default
      setUpSlider(widget, widget)
    when "inputBox"
      setUpInputBox(widget, widget)
    when "button"
      setUpButton(reportError, updateUI)(widget, widget)
    when "chooser"
      setUpChooser(widget, widget)
    when "monitor"
      setUpMonitor(widget, widget)
    when "plot"
      setUpPlot(plotSetupHelper)(widget, widget)
    when "hnwSwitch"
      setUpHNWSwitch(widget, widget)
    when "hnwSlider"
      widget.currentValue = widget.default
      setUpHNWSlider(widget, widget)
    when "hnwInputBox"
      setUpHNWInputBox(widget, widget)
    when "hnwButton"
      setUpHNWButton(updateUI)(widget, widget)
    when "hnwChooser"
      setUpHNWChooser(widget, widget)
    when "hnwMonitor"
      setUpHNWMonitor(widget, widget)
    when "hnwPlot"
      setUpHNWPlot(plotSetupHelper)(widget, widget)
    when "hnwView"
      setUpHNWView(widget, widget)
  return

# (InputBox, InputBox) => Unit
setUpInputBox = (source, destination) ->
  destination.boxedValue   = source.boxedValue
  destination.currentValue = destination.boxedValue.value
  destination.variable     = source.variable
  destination.display      = destination.variable
  return

# (PlotHelper) => (Plot, Plot) => Unit
setUpPlot = (helper) -> (source, destination) ->

  divId = "#netlogo-#{source.type}-#{destination.id}"

  destination.autoPlotOn         = source.autoPlotOn
  destination.bottom             = source.bottom
  destination.compilation        = source.compilation
  destination.compiledPens       = source.compiledPens
  destination.compiledSetupCode  = source.compiledSetupCode
  destination.compiledUpdateCode = source.compiledUpdateCode
  destination.display            = source.display
  destination.id                 = source.id
  destination.left               = source.left
  destination.legendOn           = source.legendOn
  destination.pens               = source.pens
  destination.right              = source.right
  destination.setupCode          = source.setupCode
  destination.top                = source.top
  destination.type               = source.type
  destination.updateCode         = source.updateCode
  destination.xAxis              = source.xAxis
  destination.xmax               = source.xmax
  destination.xmin               = source.xmin
  destination.yAxis              = source.yAxis
  destination.ymax               = source.ymax
  destination.ymin               = source.ymin

  pops = helper.getPlotOps()
  hops = new HighchartsOps(helper.lookupElem(divId))
  hops.setBGColor("#efefef")
  pops[source.display] = hops

  plots     = helper.getPlotComps()
  component = plots.find((plot) -> plot.get("widget").display is source.display)
  component.set('resizeCallback', hops.resizeElem.bind(hops))

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

# Returns `true` when a stop interrupt was returned or an error/halt was thrown.
# ((String, String, Exception) => Unit, () => Any, String | undefined) => Boolean
runWithErrorHandling = (source, reportError, f, code) ->
  try
    f() is StopInterrupt
  catch ex
    if not (ex instanceof Exception.HaltInterrupt)
      reportError("runtime", source, ex, code)
    true

# ((String, String, Exception) => Unit, () => Unit, Button, () => Any) => () => Unit
makeRunForeverTask = (reportError, updateUI, button, f, code) -> () ->
  mustStop = runWithErrorHandling("button", reportError, f, code)
  if mustStop
    button.running = false
    updateUI()
  return

# ((String, String, Exception) => Unit, () => Unit, () => Any) => () => Unit
makeRunOnceTask = (reportError, updateUI, f, code) -> () ->
  runWithErrorHandling("button", reportError, f, code)
  updateUI()
  return

# ((String, String, Exception) => Unit, Button, Array[String]) => () => Unit
makeCompilerErrorTask = (reportError, button, errors) -> () ->
  button.running = false
  reportError('compiler', 'button', ['Button failed to compile with:'].concat(errors))
  return

# ((String, String, Exception) => Unit, () => Unit) => (Button, Button) => Unit
setUpButton = (reportError, updateUI) -> (source, destination) ->
  if source.forever
    destination.running = false

  if source.compilation?.success
    code = if source.display? then source.display else source.source
    destination.compiledSource = source.compiledSource
    f = new Function(destination.compiledSource)
    destination.run = if source.forever
      makeRunForeverTask(reportError, updateUI, destination, f, code)
    else
      makeRunOnceTask(reportError, updateUI, f, code)

  else
    destination.run = makeCompilerErrorTask(reportError, destination, source.compilation?.messages ? [])

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
    destination.getStep = () -> 0.001

  destination.minValue  = destination.currentValue
  destination.maxValue  = destination.currentValue + 1
  destination.stepValue = 0.001
  return

# (HNWInputBox, HNWInputBox) => Unit
setUpHNWInputBox = (source, destination) ->
  destination.boxedValue   = source.boxedValue
  destination.currentValue = destination.boxedValue.value
  destination.variable     = source.variable
  destination.display      = destination.variable
  return

# (HNWSwitch, HNWSwitch) => Unit
setUpHNWSwitch = (source, destination) ->
  destination.on           = source.on
  destination.currentValue = destination.on
  return

# (HNWChooser, HNWChooser) => Unit
setUpHNWChooser = (source, destination) ->
  destination.choices       = source.choices
  destination.currentChoice = source.currentChoice
  destination.currentValue  = destination.choices[destination.currentChoice]
  return

# (() => Unit) => (HNWButton, HNWButton) => Unit
setUpHNWButton = (updateUI) -> (source, destination) ->
  if source.forever then destination.running = false
  destination.run = source.hnwSource
  return

# (HNWMonitor, HNWMonitor) => Unit
setUpHNWMonitor = (source, destination) ->
  if source.compilation?.success
    destination.compiledSource = source.compiledSource
    destination.reporter       = reporterOf(destination.compiledSource)
    destination.currentValue   = ""
  else
    destination.reporter     = () -> "N/A"
    destination.currentValue = "N/A"
  return

# (PlotHelper) => (HNWPlot, HNWPlot) => Unit
setUpHNWPlot = (helper) -> (source, destination) ->

  destination.autoPlotOn         = source.autoPlotOn
  destination.bottom             = source.bottom
  destination.compilation        = source.compilation
  destination.compiledPens       = source.compiledPens
  destination.compiledSetupCode  = source.compiledSetupCode
  destination.compiledUpdateCode = source.compiledUpdateCode
  destination.display            = source.display
  destination.id                 = source.id
  destination.left               = source.left
  destination.legendOn           = source.legendOn
  destination.pens               = source.pens
  destination.right              = source.right
  destination.setupCode          = source.setupCode
  destination.top                = source.top
  destination.type               = source.type
  destination.updateCode         = source.updateCode
  destination.xAxis              = source.xAxis
  destination.xmax               = source.xmax
  destination.xmin               = source.xmin
  destination.yAxis              = source.yAxis
  destination.ymax               = source.ymax
  destination.ymin               = source.ymin

  pops = helper.getPlotOps()
  hops = new HighchartsOps(helper.lookupElem("#netlogo-#{source.type}-#{source.id}"))
  pops[source.display] = hops

  plots     = helper.getPlotComps()
  component = plots.find((plot) -> plot.get("widget").display is source.display)
  component.set('resizeCallback', hops.resizeElem.bind(hops))

  { display, id, legendOn, type, xAxis, xmax, xmin, yAxis, ymax, ymin } = source

  dummyPlot = { isLegendEnabled: legendOn
              , name:            display
              , xLabel:          xAxis
              , yLabel:          yAxis
              }

  for _, pen of source.pens

    numToMode = (num) ->
      { Bar, Line, Point } = tortoise_require('engine/plot/pen').DisplayMode
      modeObj =
        switch num
          when 0 then Line
          when 1 then Bar
          when 2 then Point
          else        Line

    # (Number) => Number
    javaColorToNetLogo = (c) ->

      componentToHex = (comp) -> Number(comp).toString(16).padStart(2, '0')
      f              = componentToHex

      r = (c & 0xFF0000) >> 16
      g = (c & 0x00FF00) >>  8
      b = (c & 0x0000FF)

      hexStringToNetlogoColor("##{f(r)}#{f(g)}#{f(b)}")

    dummyPen = { name:               pen.display
               , getColor:       (-> javaColorToNetLogo(pen.color))
               , getDisplayMode: (-> numToMode(pen.mode))
               , getInterval:    (-> pen.interval)
               , isFake:         true
               }

  fakePlot =
    { isLegendEnabled: destination.legendOn
    , name:            destination.display
    , xLabel:          destination.xAxis
    , yLabel:          destination.yAxis
    }

  hops.reset(fakePlot)

  return

# (HNWSlider, HNWSlider) => Unit
setUpHNWSlider = (source, destination) ->

  destination.default = source.default
  destination.min     = source.min
  destination.max     = source.max
  destination.step    = source.step

  destination.getMin  = reporterOf(destination.min)
  destination.getMax  = reporterOf(destination.max)
  destination.getStep = reporterOf(destination.step)

  destination.minValue  = destination.currentValue
  destination.maxValue  = destination.currentValue + 1
  destination.stepValue = 0.001

  return

# (HNWView, HNWView) => Unit
setUpHNWView = (source, destination) ->
  return

export {
  setUpWidgets,
  setUpWidget,
  setUpInputBox,
  setUpSwitch,
  setUpChooser,
  setUpButton,
  setUpMonitor,
  setUpPlot,
  setUpSlider,
  setUpHNWButton,
  setUpHNWChooser,
  setUpHNWInputBox,
  setUpHNWMonitor,
  setUpHNWPlot,
  setUpHNWSlider,
  setUpHNWSwitch,
  setUpHNWView,
  runWithErrorHandling,
}
