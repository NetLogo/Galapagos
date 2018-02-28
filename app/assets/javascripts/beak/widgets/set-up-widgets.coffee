# (Array[Widget], () => Unit) => Unit
window.setUpWidgets = (widgets, updateUI) ->

  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  for widget, id in widgets
    setUpWidget(widget, id, updateUI)

  return

reporterOf = (str) -> new Function("return #{str}")

# Destructive - Adds everything for maintaining state to the widget models,
# such `currentValue`s and actual functions for buttons instead of just code.
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
  return

# (InputBox, InputBox) => Unit
window.setUpInputBox = (source, destination) ->
  destination.boxedValue   = source.boxedValue
  destination.currentValue = destination.boxedValue.value
  destination.variable     = source.variable
  destination.display      = destination.variable
  return

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
