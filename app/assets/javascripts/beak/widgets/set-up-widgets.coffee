# ((String, Exception) => Unit, Array[Widget], () => Unit) => Unit
window.setUpWidgets = (reportError, widgets, updateUI) ->
  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  for widget, id in widgets
    setUpWidget(reportError, widget, id, updateUI)

  return

reporterOf = (str) -> new Function("return #{str}")

# Destructive - Adds everything for maintaining state to the widget models,
# such `currentValue`s and actual functions for buttons instead of just code.
# ((String, String, Exception) => Unit, Widget, String, () => Unit) => Unit
window.setUpWidget = (reportError, widget, id, updateUI) ->
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

# Returns `true` when a stop interrupt was returned or an error/halt was thrown.
# ((String, String, Exception) => Unit, () => Any) => Boolean
window.runWithErrorHandling = (source, reportError, f) ->
  try
    f() is StopInterrupt
  catch ex
    if not (ex instanceof Exception.HaltInterrupt)
      reportError("runtime", source, ex)
    true

# ((String, String, Exception) => Unit, () => Unit, Button, () => Any) => () => Unit
makeRunForeverTask = (reportError, updateUI, button, f) -> () ->
  mustStop = window.runWithErrorHandling("button", reportError, f)
  if mustStop
    button.running = false
    updateUI()
  return

# ((String, String, Exception) => Unit, () => Unit, () => Any) => () => Unit
makeRunOnceTask = (reportError, updateUI, f) -> () ->
  window.runWithErrorHandling("button", reportError, f)
  updateUI()
  return

# ((String, String, Exception) => Unit, Button, Array[String]) => () => Unit
makeCompilerErrorTask = (reportError, button, errors) -> () ->
  button.running = false
  reportError('compiler', 'button', ['Button failed to compile with:'].concat(errors))
  return

# ((String, String, Exception) => Unit, () => Unit) => (Button, Button) => Unit
window.setUpButton = (reportError, updateUI) -> (source, destination) ->
  if source.forever
    destination.running = false

  if source.compilation?.success
    destination.compiledSource = source.compiledSource
    f = new Function(destination.compiledSource)
    destination.run = if source.forever
      makeRunForeverTask(reportError, updateUI, destination, f)
    else
      makeRunOnceTask(reportError, updateUI, f)

  else
    destination.run = makeCompilerErrorTask(reportError, destination, source.compilation?.messages ? [])

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
