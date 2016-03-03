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
    s.slice(0, -6)

  model = {
    widgets,
    speed:              0.0,
    ticks:              "", # Remember, ticks initialize to nothing, not 0
    ticksStarted:       false,
    width:              Math.max.apply(Math, (w.right  for w in widgets)),
    height:             Math.max.apply(Math, (w.bottom for w in widgets)),
    code,
    info,
    readOnly,
    lastCompiledCode:   code,
    isStale:            false,
    exportForm:         false,
    modelTitle:         dropNLogoExtension(filename),
    consoleOutput:      '',
    outputWidgetOutput: '',
    markdown:           sanitizedMarkdown,
    hasFocus:           false,
    isEditing:          false
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

      console:       RactiveConsoleWidget,
      editableTitle: RactiveModelTitle,
      editor:        RactiveEditorWidget,
      infotab:       RactiveInfoTabWidget,

      labelWidget:   RactiveLabel,
      switchWidget:  RactiveSwitch,
      buttonWidget:  RactiveButton,
      sliderWidget:  RactiveSlider,
      chooserWidget: RactiveChooser,
      monitorWidget: RactiveMonitor,
      inputWidget:   RactiveInput,
      outputWidget:  RactiveOutputArea,
      plotWidget:    RactivePlot,
      viewWidget:    RactiveView

    },
    magic:      true,
    data:       model,
    oncomplete: attachWidgetMenus
  })

  mousetrap = Mousetrap(container.querySelector('.netlogo-model'))
  mousetrap.bind(['ctrl+shift+alt+i', 'command+shift+alt+i'], => ractive.fire('toggleInterfaceLock'))

  viewModel = widgets.filter((w) -> w.type == 'view')[0]
  viewController = new AgentStreamController(container.querySelector('.netlogo-view-container'), viewModel.fontSize)

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
    write: (str) -> model.outputWidgetOutput += str
    clear: -> model.outputWidgetOutput = ""
  }

  dialog = {
    confirm: (str) -> clearMouse(); window.confirm(str)
    notify:  (str) -> clearMouse(); window.nlwAlerter.display("NetLogo Notification", true, str)
  }

  ractive.observe('widgets.*.currentValue', (newVal, oldVal, keyPath, widgetNum) ->
    widget = widgets[widgetNum]
    if world? and newVal != oldVal and isValidValue(widget, newVal)
      world.observer.setGlobal(widget.varName, newVal)
  )

  ractive.on('checkFocus', (event) ->
    @set('hasFocus', document.activeElement is event.node)
  )

  ractive.on('checkActionKeys', (event) ->
    if @get('hasFocus')
      e = event.original
      char = String.fromCharCode(if e.which? then e.which else e.keyCode)
      for w in widgets when w.type is 'button' and w.actionKey is char
        w.run()
  )

  setupInterfaceEditor(ractive)

  controller = new WidgetController(ractive, model, widgets, viewController, plotOps, mouse, write, output, dialog)

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
             More information about these sorts of errors can be found <a href="/info#type-errors">here</a>.<br><br>
             Advanced users might find the generated error helpful, which is as follows:<br><br>
             <b>#{ex.message}</b><br><br>
             """
      showErrors([message])
      throw new Exception.HaltInterrupt
    else
      throw ex

class window.WidgetController
  constructor: (@ractive, @model, @widgets, @viewController, @plotOps, @mouse, @write, @output, @dialog) ->

  # () -> Unit
  runForevers: ->
    for widget in @widgets
      if widget.type == 'button' and widget.forever and widget.running
        widget.run()

  # () -> Unit
  updateWidgets: ->
    for _, chartOps of @plotOps
      chartOps.redraw()

    for widget, i in @widgets
      if widget.currentValue?
        if widget.varName?
          widget.currentValue = world.observer.getGlobal(widget.varName)
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
    if world.ticker.ticksAreStarted()
      @model.ticks = Math.floor(world.ticker.tickCount())
      @model.ticksStarted = true
    else
      @model.ticks = ''
      @model.ticksStarted = false

  # () -> number
  speed: -> @model.speed

  # () -> Unit
  redraw: () ->
    if Updater.hasUpdates() then @viewController.update(Updater.collectUpdates())

  # () -> Unit
  teardown: -> @ractive.teardown()

  code: -> @ractive.get('code')

reporterOf = (str) -> new Function("return #{str}")

# ([widget], () -> Unit) -> WidgetController
# Destructive - Adds everything for maintaining state to the widget models,
# such `currentValue`s and actual functions for buttons instead of just code.
fillOutWidgets = (widgets, updateUICallback) ->
  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  idCounter = 0
  for widget in widgets
    widget.idNum = idCounter++
    if widget.varName?
      # Convert from NetLogo variables to Tortoise variables.
      widget.varName = widget.varName.toLowerCase()
    switch widget['type']
      when "switch"
        widget.currentValue = widget.on
      when "slider"
        widget.currentValue = widget.default
        if widget.compilation.success
          widget.getMin  = reporterOf(widget.compiledMin)
          widget.getMax  = reporterOf(widget.compiledMax)
          widget.getStep = reporterOf(widget.compiledStep)
        else
          widget.getMin  = () -> widget.default
          widget.getMax  = () -> widget.default
          widget.getStep = () -> 0
        widget.minValue     = widget.default
        widget.maxValue     = widget.default + 1
        widget.stepValue    = 1
      when "inputBox"
        widget.currentValue = widget.value
      when "button"
        if widget.forever then widget.running = false
        do (widget) ->
          if widget.compilation.success
            task = window.handlingErrors(new Function(widget.compiledSource))
            do (task) ->
              wrappedTask =
                if widget.forever
                  () ->
                    mustStop =
                      try task() instanceof Exception.StopInterrupt
                      catch ex
                        ex instanceof Exception.HaltInterrupt
                    if mustStop
                      widget.running = false
                      updateUICallback()
                else
                  () ->
                    task()
                    updateUICallback()
              do (wrappedTask) ->
                widget.run = wrappedTask
          else
            widget.run = () -> showErrors(["Button failed to compile with:\n" +
                                           widget.compilation.messages.join('\n')])
      when "chooser"
        widget.currentValue = widget.choices[widget.currentChoice]
      when "monitor"
        if widget.compilation.success
          widget.reporter     = reporterOf(widget.compiledSource)
          widget.currentValue = ""
        else
          widget.reporter     = () -> "N/A"
          widget.currentValue = "N/A"


# (Element, [widget]) -> [HighchartsOps]
# Creates the plot ops for Highchart interaction.
createPlotOps = (container, widgets) ->
  plotOps = {}
  for widget in widgets
    if widget.type == "plot"
      plotOps[widget.display] = new HighchartsOps(
        container.querySelector("#netlogo-plot-#{widget.idNum}")
      )
  plotOps

# (widget, Any) -> Boolean
isValidValue = (widget, value) ->
  switch widget.type
    when 'slider'   then not isNaN(value)
    when 'inputBox' then not (widget.boxtype == 'Number' and isNaN(value))
    else  true

# coffeelint: disable=max_line_length
template =
  """
  <div class="netlogo-model" style="width: {{width}}px;"
       tabindex="1" on-keydown="checkActionKeys" on-focus="checkFocus" on-blur="checkFocus">
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
      <div class="netlogo-export-wrapper">
        <span style="margin-right: 4px;">Export:</span>
        <button class="netlogo-ugly-button" on-click="exportnlogo">NetLogo</button>
        <button class="netlogo-ugly-button" on-click="exportHtml">HTML</button>
      </div>
      {{/}}
    </div>

    <div id="netlogo-widget-context-menu" class="widget-context-menu">
      <div id='widget-creation-disabled-message' style="display: none;">
        Widget creation is not yet available.  Check back soon.
      </div>
    </div>

    <div class="netlogo-interface-unlocker" style="display: none" on-click="toggleInterfaceLock"></div>

    <label class="netlogo-widget netlogo-speed-slider">
      <input type="range" min=-1 max=1 step=0.01 value={{speed}} />
      <span class="netlogo-label">speed</span>
    </label>

    <div style="position: relative; width: {{width}}px; height: {{height}}px"
         class="netlogo-widget-container"
         on-contextmenu="showContextMenu:{{'widget-creation-disabled-message'}}">
      {{#widgets}}
        {{# type === 'view'     }} <viewWidget    id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} ticks="{{ticks}}" /> {{/}}
        {{# type === 'textBox'  }} <labelWidget   id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} /> {{/}}
        {{# type === 'switch'   }} <switchWidget  id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} /> {{/}}
        {{# type === 'button'   }} <buttonWidget  id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} errorClass="{{>errorClass}}" ticksStarted="{{ticksStarted}}"/> {{/}}
        {{# type === 'slider'   }} <sliderWidget  id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} errorClass="{{>errorClass}}" /> {{/}}
        {{# type === 'chooser'  }} <chooserWidget id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} /> {{/}}
        {{# type === 'monitor'  }} <monitorWidget id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} errorClass="{{>errorClass}}" /> {{/}}
        {{# type === 'inputBox' }} <inputWidget   id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} /> {{/}}
        {{# type === 'plot'     }} <plotWidget    id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} /> {{/}}
        {{# type === 'output'   }} <outputWidget  id="{{>widgetID}}" dims="{{>dimensions}}" widget={{this}} output="{{outputWidgetOutput}}" /> {{/}}
      {{/}}
    </div>

    <div class="netlogo-tab-area">
      {{# !readOnly }}
      <label class="netlogo-tab{{#showConsole}} netlogo-active{{/}}">
        <input id="console-toggle" type="checkbox" checked="{{showConsole}}" />
        <span class="netlogo-tab-text">Command Center</span>
      </label>
      {{#showConsole}}
        <console output="{{consoleOutput}}"/>
      {{/}}
      {{/}}
      <label class="netlogo-tab{{#showCode}} netlogo-active{{/}}">
        <input id="code-tab-toggle" type="checkbox" checked="{{ showCode }}" />
        <span class="netlogo-tab-text">NetLogo Code</span>
      </label>
      {{#showCode}}
        <editor code='{{code}}' readOnly='{{readOnly}}' />
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

  dimensions:
    """
    position: absolute;
    left: {{ left }}px; top: {{ top }}px;
    width: {{ right - left }}px; height: {{ bottom - top }}px;
    """

  widgetID:
    """
    netlogo-{{type}}-{{idNum}}
    """

}
# coffeelint: enable=max_line_length
