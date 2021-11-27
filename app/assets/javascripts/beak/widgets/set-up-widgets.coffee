# (Array[Widget], () => Unit) => Unit
window.setUpWidgets = (widgets, updateUI) ->

  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  for widget, id in widgets
    setUpWidget(widget, id, updateUI)

  return

reporterOf = (str) -> new Function("return #{str}")

# Destructive; adds everything for maintaining state to the widget models, such as
# `currentValue`s and actual functions for buttons instead of just code.
window.setUpWidget = (widget, id, updateUI) ->
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
      setUpButton(updateUI)(widget, widget)
    when "chooser"
      setUpChooser(widget, widget)
    when "monitor"
      setUpMonitor(widget, widget)
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
    when "hnwView"
      setUpHNWView(widget, widget)
  return

# (InputBox, InputBox) => Unit
window.setUpInputBox = (source, destination) ->
  destination.boxedValue   = source.boxedValue
  destination.currentValue = destination.boxedValue.value
  destination.variable     = source.variable
  destination.display      = destination.variable
  return

window.setUpPlot = (source, destination) ->

  # (String, Widget.Plot) => Unit
  updatePlotConfig = (oldName, plot) ->

      hops = new HighchartsOps(container.querySelector("#netlogo-#{plot.type}-#{plot.id}"))
      delete controller.configs.plotOps[oldName]
      controller.configs.plotOps[plot.display] = hops

      for display, chartOps of @configs.plotOps
        normies   = @ractive.findAllComponents("plotWidget")
        hnws      = @ractive.findAllComponents("hnwPlotWidget")
        component = [].concat(normies, hnws).find((plot) -> plot.get("widget").display is display)
        component.set('resizeCallback', chartOps.resizeElem.bind(chartOps))

# (Switch, Switch) => Unit
window.setUpSwitch = (source, destination) ->
  destination.on           = source.on
  destination.currentValue = destination.on
  return

# (Chooser, Chooser) => Unit
window.setUpChooser = (source, destination) ->
  destination.choices       = source.choices
  destination.currentChoice = source.currentChoice
  destination.currentValue  = destination.choices[destination.currentChoice]
  return

# (() => Unit) => (Button, Button) => Unit
window.setUpButton = (updateUI) -> (source, destination) ->
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
window.setUpMonitor = (source, destination) ->
  if source.compilation?.success
    destination.compiledSource = source.compiledSource
    destination.reporter       = reporterOf(destination.compiledSource)
    destination.currentValue   = ""
  else
    destination.reporter     = () -> "N/A"
    destination.currentValue = "N/A"
  return

# (Slider, Slider) => Unit
window.setUpSlider = (source, destination) ->
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
window.setUpHNWInputBox = (source, destination) ->
  destination.boxedValue   = source.boxedValue
  destination.currentValue = destination.boxedValue.value
  destination.variable     = source.variable
  destination.display      = destination.variable
  return

# (HNWSwitch, HNWSwitch) => Unit
window.setUpHNWSwitch = (source, destination) ->
  destination.on           = source.on
  destination.currentValue = destination.on
  return

# (HNWChooser, HNWChooser) => Unit
window.setUpHNWChooser = (source, destination) ->
  destination.choices       = source.choices
  destination.currentChoice = source.currentChoice
  destination.currentValue  = destination.choices[destination.currentChoice]
  return

# (() => Unit) => (HNWButton, HNWButton) => Unit
window.setUpHNWButton = (updateUI) -> (source, destination) ->
  if source.forever then destination.running = false
  destination.run = source.hnwSource
  return

# (HNWMonitor, HNWMonitor) => Unit
window.setUpHNWMonitor = (source, destination) ->
  if source.compilation?.success
    destination.compiledSource = source.compiledSource
    destination.reporter       = reporterOf(destination.compiledSource)
    destination.currentValue   = ""
  else
    destination.reporter     = () -> "N/A"
    destination.currentValue = "N/A"
  return

# (HNWPlot, HNWPlot) => Unit
window.setUpHNWPlot = (source, destination) ->
  return

# (HNWSlider, HNWSlider) => Unit
window.setUpHNWSlider = (source, destination) ->

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
window.setUpHNWView = (source, destination) ->
  return
