dropNLogoExtension = (s) ->
  if s.match(/.*\.nlogo/)?
    s.slice(0, -6)
  else
    s

# (Element, Array[Widget], String, String, Boolean, String, String, (String) => Boolean) => Ractive
window.generateRactiveSkeleton = (container, widgets, code, info, isReadOnly, filename, checkIsReporter) ->

  model = {
    checkIsReporter
  , code
  , consoleOutput:      ''
  , exportForm:         false
  , hasFocus:           false
  , height:             0
  , info
  , isEditing:          false
  , isReadOnly
  , isStale:            false
  , lastCompiledCode:   code
  , lastCompileFailed:  false
  , lastDragX:          undefined
  , lastDragY:          undefined
  , modelTitle:         dropNLogoExtension(filename)
  , outputWidgetOutput: ''
  , primaryView:        undefined
  , speed:              0.0
  , ticks:              "" # Remember, ticks initialize to nothing, not 0
  , ticksStarted:       false
  , widgetObj:          widgets.reduce(((acc, widget, index) -> acc[index] = widget; acc), {})
  , width:              0
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

  new Ractive({
    el:         container,
    template:   template,
    partials:   partials,
    components: {

      console:       RactiveConsoleWidget
    , contextMenu:   RactiveContextMenu
    , editableTitle: RactiveModelTitle
    , codePane:      RactiveModelCodeComponent
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

# coffeelint: disable=max_line_length
template =
  """
  <div class="netlogo-model" style="min-width: {{width}}px;"
       tabindex="1" on-keydown="@this.fire('check-action-keys', @event)"
       on-focus="@this.fire('track-focus', @node)"
       on-blur="@this.fire('track-focus', @node)">
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
      {{# !isReadOnly }}
        <div class="flex-column" style="align-items: flex-end; user-select: none;">
          <div class="netlogo-export-wrapper">
            <span style="margin-right: 4px;">File:</span>
            <button class="netlogo-ugly-button" on-click="open-new-file"{{#isEditing}} disabled{{/}}>New</button>
          </div>
          <div class="netlogo-export-wrapper">
            <span style="margin-right: 4px;">Export:</span>
            <button class="netlogo-ugly-button" on-click="export-nlogo"{{#isEditing}} disabled{{/}}>NetLogo</button>
            <button class="netlogo-ugly-button" on-click="export-html"{{#isEditing}} disabled{{/}}>HTML</button>
          </div>
        </div>
      {{/}}
    </div>

    <div class="netlogo-interface-unlocker" style="display: none" class="{{#isEditing}}interface-unlocked{{/}}" on-click="toggle-interface-lock"></div>

    <contextMenu></contextMenu>

    <label class="netlogo-speed-slider{{#isEditing}} interface-unlocked{{/}}">
      <span class="netlogo-label">model speed</span>
      <input type="range" min=-1 max=1 step=0.01 value="{{speed}}"{{#isEditing}} disabled{{/}} />
      <tickCounter isVisible="{{primaryView.showTickCounter}}"
                   label="{{primaryView.tickCounterLabel}}" value="{{ticks}}" />
    </label>

    <div style="position: relative; width: {{width}}px; height: {{height}}px"
         class="netlogo-widget-container"
         on-contextmenu="@this.fire('show-context-menu', { component: @this }, @event)"
         on-click="@this.fire('deselect-widgets', @event)" on-dragover="hail-satan">
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
      {{# !isReadOnly }}
      <label class="netlogo-tab{{#showConsole}} netlogo-active{{/}}">
        <input id="console-toggle" type="checkbox" checked="{{showConsole}}" />
        <span class="netlogo-tab-text">Command Center</span>
      </label>
      {{#showConsole}}
        <console output="{{consoleOutput}}" isEditing="{{isEditing}}" checkIsReporter="{{checkIsReporter}}" />
      {{/}}
      {{/}}
      <label class="netlogo-tab{{#showCode}} netlogo-active{{/}}">
        <input id="code-tab-toggle" type="checkbox" checked="{{ showCode }}" />
        <span class="netlogo-tab-text{{#lastCompileFailed}} netlogo-widget-error{{/}}">NetLogo Code</span>
      </label>
      {{#showCode}}
        <codePane code='{{code}}' lastCompiledCode='{{lastCompiledCode}}' lastCompileFailed='{{lastCompileFailed}}' isReadOnly='{{isReadOnly}}' />
      {{/}}
      <label class="netlogo-tab{{#showInfo}} netlogo-active{{/}}">
        <input id="info-toggle" type="checkbox" checked="{{ showInfo }}" />
        <span class="netlogo-tab-text">Model Info</span>
      </label>
      {{#showInfo}}
        <infotab rawText='{{info}}' isEditing='{{isEditing}}' />
      {{/}}
    </div>

    <input id="import-world-input" type="file" name="import-world" style="display: none;" />

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
