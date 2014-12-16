# (Element or string, [widget], string, string) -> WidgetController
window.bindWidgets = (container, widgets, code, info, readOnly) ->
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

  model = {
    widgets,
    speed:    0.0,
    ticks:    "", # Remember, ticks initialize to nothing, not 0
    width:    Math.max.apply(Math, (w.right  for w in widgets)),
    height:   Math.max.apply(Math, (w.bottom for w in widgets)),
    code,
    info,
    readOnly,
    markdown: markdown.toHTML
  }

  ractive = new Ractive({
    el:         container,
    template:   template,
    partials:   partials,
    components: {
      editor: EditorWidget
    },
    magic:      true,
    data:       model
  })

  viewController = new AgentStreamController(container.querySelector('.netlogo-view-container'))

  plotOps = createPlotOps(container, widgets)

  ractive.observe('widgets.*.currentValue', (newVal, oldVal, keyPath, widgetNum) ->
    widget = widgets[widgetNum]
    if world? and newVal != oldVal and isValidValue(widget, newVal)
      world.observer.setGlobal(widget.varName, newVal)
  )
  ractive.on('activateButton', (event) ->
    event.context.run()
  )

  controller = new WidgetController(ractive, model, widgets, viewController, plotOps)


class window.WidgetController
  constructor: (@ractive, @model, @widgets, @viewController, @plotOps) ->

  # () -> Unit
  runForevers: ->
    for widget in @widgets
      if widget.type == 'button' and widget.forever and widget.running
        widget.run()

  # () -> Unit
  updateWidgets: ->
    for widget, i in @widgets
      if widget.currentValue?
        if widget.varName?
          widget.currentValue = world.observer.getGlobal(widget.varName)
        else if widget.reporter?
          try
            widget.currentValue = widget.reporter()
          catch err
            widget.currentValue = 'N/A'
        if widget.precision? and typeof widget.currentValue == 'number' and isFinite(widget.currentValue)
          widget.currentValue = Prims.precision(widget.currentValue, widget.precision)
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
    try
      @model.ticks = world.ticker.tickCount()
    catch err
      # ignore

  # () -> number
  speed: -> @model.speed

  # () -> Unit
  redraw: () -> if Updater.hasUpdates() then @viewController.update(Updater.collectUpdates())

  # () -> Unit
  teardown: -> @ractive.teardown()

  code: -> @ractive.data.code

# ([widget], () -> Unit) -> WidgetController
# Destructive - Adds everything for maintaining state to the widget models,
# such `currentValue`s and actual functions for buttons instead of just code.
fillOutWidgets = (widgets, updateUICallback) ->
  # Note that this must execute before models so we can't call any model or
  # engine functions. BCH 11/5/2014
  plotCount = 0
  for widget in widgets
    if widget.varName?
      # Convert from NetLogo variables to Tortoise variables.
      widget.varName = widget.varName.toLowerCase()
    switch widget['type']
      when "switch"
        widget.currentValue = widget.on
      when "slider"
        widget.currentValue = widget.default
        widget.getMin       = new Function("return " + widget.compiledMin.result)
        widget.getMax       = new Function("return " + widget.compiledMax.result)
        widget.getStep      = new Function("return " + widget.compiledStep.result)
        widget.minValue     = widget.default
        widget.maxValue     = widget.default + 1
        widget.stepValue    = 1
      when "inputBox"
        widget.currentValue = widget.value
      when "button"
        if widget.forever then widget.running = false
        if widget.compiledSource.success
          task = new Function(widget.compiledSource.result)
          do (task) ->
            widget.run = if widget.forever then task else () ->
              task()
              updateUICallback()
        else
          widget.run = () -> alert("Button failed to compile with:\n" +
                                  (res.message for res in widget.compiledSource.result).join('\n'))
      when "chooser"
        widget.currentValue = widget.choices[widget.currentChoice]
      when "monitor"
        widget.reporter     = new Function("return " + widget.compiledSource.result)
        widget.currentValue = ""
      when "plot"
        widget.plotNumber = plotCount++


# (Element, [widget]) -> [HighchartsOps]
# Creates the plot ops for Highchart interaction.
createPlotOps = (container, widgets) ->
  plotOps = {}
  for widget in widgets
    if widget.type == "plot"
      plotOps[widget.display] = new HighchartsOps(
        container.querySelector(".netlogo-plot-#{widget.plotNumber}")
      )
  plotOps

# (widget, Any) -> Boolean
isValidValue = (widget, value) ->
  switch widget.type
    when 'slider'   then not isNaN(value)
    when 'inputBox' then if widget.boxtype == 'Number' then not isNaN(value)
    else  true

template =
  """
  <div class="netlogo-model" style="width: {{width}};">
    <div class="netlogo-header">
      <label class="netlogo-widget netlogo-speed-slider">
        <span class="netlogo-label">speed</span>
        <input type="range" min=-1 max=1 step=0.01 value={{speed}} />
      </label>

      <div class="netlogo-powered-by">
        <a href="http://ccl.northwestern.edu/netlogo/">
          <img style="vertical-align: middle;" alt="NetLogo" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAANcSURBVHjarJRdaFxFFMd/M/dj7252uxubKms+bGprVyIVbNMWWqkQqtLUSpQWfSiV+oVFTcE3DeiDgvoiUSiCYLH2oVoLtQ+iaaIWWtE2FKGkkSrkq5svN+sm7ma/7p3x4W42lEbjQw8MM8yc87/nzPnNFVprbqWJXyMyXuMqx1Ni6N3ny3cX8tOHNLoBUMvESoFI2Xbs4zeO1lzREpSrMSNS1zkBDv6uo1/noz1H7mpvS4SjprAl2AZYEqzKbEowBAgBAkjPKX2599JjT7R0bj412D0JYNplPSBD1G2SmR/e6u1ikEHG2vYiGxoJmxAyIGSCI8GpCItKimtvl2JtfGujDNkX6epuAhCjNeAZxM1ocPy2Qh4toGQ5DLU+ysiuA2S3P0KgJkjAgEAlQylAA64CG/jlUk6//ng4cNWmLK0yOPNMnG99Rs9LQINVKrD+wmke7upg55PrWP3eYcwrlykpKCkoelDy/HVegQhoABNAepbACwjOt72gZkJhypX70YDWEEklue+rbnYc2MiGp1upPfYReiJJUUG58gFXu4udch1wHcjFIgy0HyIjb2yvBpT2F6t+6+f+D15lW8c9JDo7iPSdgVIRLUqL2AyHDQAOf9hfbqxvMF98eT3RuTS1avHyl+Stcphe2chP9+4k/t3RbXVl3W+Ws17FY56/w3VcbO/koS/eZLoAqrQMxADZMTYOfwpwoWjL4+bCYcgssMqGOzPD6CIkZ/3SxTJ0ayFIN6/BnBrZb2XdE1JUgkJWkfrUNRJnPyc16zsbgPyXIUJBpvc+y89nk/S8/4nek3NPGeBWMwzGvhUPnP6RubRLwfODlqqx3LSCyee2MnlwMwA2RwgO5qouVcHmksUdJweYyi8hZkrUjgT5t/ejNq0jBsSqNWsKyT9uFtxw7Bs585d3g46KOeT2bWHmtd14KyP+5mzqpsYU3OyioACMhGiqPTMocsrHId9cy9BLDzKxq8X3ctMwlV6yKSHL4fr4dd0DeQBTBUgUkvpE1kVPbqkX117ZzuSaFf4zyfz5n9A4lk0yNU7vyb7jTy1kmFGipejKvh6h9n0W995ZPTu227hqmCz33xXgFV1v9NzI96NfjndWt7XWCB/7BSICFWL+j3lAofpCtfYFb6X9MwCJZ07mUsXRGwAAAABJRU5ErkJggg=="/>
          <span style="font-size: 16px;">powered by NetLogo</span>
        </a>
      </div>
    </div>

    <div style="position: relative; width: {{width}}; height: {{height}}"
         class="netlogo-widget-container">
      {{#widgets}}
        {{# type === 'view'               }} {{>view         }} {{/}}
        {{# type === 'textBox'            }} {{>textBox      }} {{/}}
        {{# type === 'switch'             }} {{>switcher     }} {{/}}
        {{# type === 'button'  && !forever}} {{>button       }} {{/}}
        {{# type === 'button'  &&  forever}} {{>foreverButton}} {{/}}
        {{# type === 'slider'             }} {{>slider       }} {{/}}
        {{# type === 'chooser'            }} {{>chooser      }} {{/}}
        {{# type === 'monitor'            }} {{>monitor      }} {{/}}
        {{# type === 'inputBox'           }} {{>inputBox     }} {{/}}
        {{# type === 'plot'               }} {{>plot         }} {{/}}
      {{/}}
    </div>

    <div class="netlogo-tabs">
      <label class="netlogo-code-tab netlogo-tab netlogo-command {{#showCode}}netlogo-active{{/}}">
        <input type="checkbox" checked="{{ showCode }}" />
        NetLogo Code
      </label>
      <label class="netlogo-info-tab netlogo-tab netlogo-command {{#showInfo}}netlogo-active{{/}}">
        <input type="checkbox" checked="{{ showInfo }}" />
        Model Info
      </label>
    </div>
    <div class="netlogo-model-text">
      {{#showCode}}
        <editor code='{{code}}' readOnly='{{readOnly}}' />
      {{/}}
      {{#showInfo}}
        <div class="netlogo-info">{{{markdown(info)}}}</div>
      {{/}}
    </div>
  </div>
  """

partials =
  view:
    """
    <div class="netlogo-widget netlogo-view-container" style="{{>dimensions}}">
      <div class="netlogo-widget netlogo-tick-counter">
        {{# showTickCounter}}
          {{tickCounterLabel}}: <span>{{ticks}}</span>
        {{/}}
      </div>
    </div>
    """
  textBox:
    """
    <pre class="netlogo-widget netlogo-text-box" style="{{>dimensions}}">{{ display }}</pre>
    """
  switcher:
    """
    <label class="netlogo-widget netlogo-switcher netlogo-input" style="{{>dimensions}}">
      <input type="checkbox" checked={{ currentValue }} />
      <span class="netlogo-label">{{ display }}</span>
    </label>
    """
  slider:
    """
    <label class="netlogo-widget netlogo-slider netlogo-input" style="{{>dimensions}}">
      <input type="range"
             max="{{maxValue}}" min="{{minValue}}" step="{{step}}" value="{{currentValue}}" />
      <span class="netlogo-label">{{display}}</span>
      <span class="netlogo-value">
        <input type="number"
               min={{minValue}} max={{maxValue}} value={{currentValue}} step={{step}} />
        {{#units}}{{units}}{{/}}
      </span>
    </label>
    """
  button:
    """
    <button class="netlogo-widget netlogo-button netlogo-command"
           type="button"
           style="{{>dimensions}}"
           on-click="activateButton">
      <span>{{display || source}}</span>
    </button>
    """
  foreverButton:
    """
    <label class="netlogo-widget netlogo-button netlogo-forever-button {{#running}}netlogo-active{{/}} netlogo-command"
           style="{{>dimensions}}">
      <input type="checkbox" checked={{ running }} />
      <span class="netlogo-label">{{display || source}}</span>
    </label>
    """
  chooser:
    """
    <label class="netlogo-widget netlogo-chooser netlogo-input" style="{{>dimensions}}">
      <span class="netlogo-label">{{display}}</span>
      <select class="netlogo-chooser-select" value="{{currentValue}}">
      {{#choices}}
        <option class="netlogo-chooser-option" value="{{.}}">{{>literal}}</option>
      {{/}}
      </select>
    </label>
    """
  monitor:
    """
    <div class="netlogo-widget netlogo-monitor netlogo-output" style="{{>dimensions}}">
      <div class="netlogo-label">{{display || source}}</div>
      <output class="netlogo-value">{{currentValue}}</output>
    </div>
   """
  inputBox:
    """
    <label class="netlogo-widget netlogo-input-box netlogo-input" style="{{>dimensions}}">
      <div class="netlogo-label">{{varName}}</div>
      {{# boxtype === 'Number'}}<input type="number" value="{{currentValue}}" />{{/}}
      {{# boxtype === 'String'}}<input type="number" value="{{currentValue}}" />{{/}}
      {{# boxtype === 'String (reporter)'}}<input type="text" value="{{currentValue}}" />{{/}}
      {{# boxtype === 'String (commands)'}}<input type="text" value="{{currentValue}}" />{{/}}
      <!-- TODO: Fix color input. It'd be nice to use html5s color input. -->
      {{# boxtype === 'Color'}}<input type="color" value="{{currentValue}}" />{{/}}
    </label>
    """
  plot:
    """
    <div class="netlogo-widget netlogo-plot netlogo-plot-{{plotNumber}} netlogo-output"
         style="{{>dimensions}}"></div>
    """

  literal:
    """
    {{# typeof . === "string"}}{{.}}{{/}}
    {{# typeof . === "number"}}{{.}}{{/}}
    {{# typeof . === "object"}}
      [{{#.}}
        {{>literal}}
      {{/}}]
    {{/}}
    """
  dimensions:
    """
    position: absolute;
    left: {{ left }}px; top: {{ top }}px;
    width: {{ right - left }}px; height: {{ bottom - top }}px;
    """
