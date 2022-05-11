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
  , goStatus:           false
  , hasFocus:           false
  , height:             0
  , info
  , isEditing:          false
  , isHelpVisible:      false
  , isHNW:              false
  , isHNWHost:          false
  , isOverlayUp:        false
  , isReadOnly
  , isResizerVisible:   true
  , isStale:            false
  , isVertical:         true
  , lastCompiledCode:   code
  , lastCompileFailed:  false
  , lastDragX:          undefined
  , lastDragY:          undefined
  , metadata:           { globalVars: [], myVars: [], procedures: [] }
  , modelTitle:         dropNLogoExtension(filename)
  , outputWidgetOutput: ''
  , primaryView:        undefined
  , someDialogIsOpen:   false
  , someEditFormIsOpen: false
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

    el:       container,
    template: template,
    partials: partials,

    components: {

      asyncDialog:   RactiveAsyncUserDialog
    , console:       RactiveConsoleWidget
    , contextMenu:   RactiveContextMenu
    , editableTitle: RactiveModelTitle
    , codePane:      RactiveModelCodeComponent
    , helpDialog:    RactiveHelpDialog
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

    , hnwLabelWidget:   RactiveHNWLabel
    , hnwSwitchWidget:  RactiveHNWSwitch
    , hnwButtonWidget:  RactiveHNWButton
    , hnwSliderWidget:  RactiveHNWSlider
    , hnwChooserWidget: RactiveHNWChooser
    , hnwMonitorWidget: RactiveHNWMonitor
    , hnwInputWidget:   RactiveHNWInput
    , hnwOutputWidget:  RactiveHNWOutputArea
    , hnwPlotWidget:    RactiveHNWPlot
    , hnwViewWidget:    RactiveHNWView

    , spacer:        RactiveEditFormSpacer

    },

    computed: {
      stateName: ->
        if @get('isEditing')
          if @get('someEditFormIsOpen')
            'authoring - editing widget'
          else
            'authoring - plain'
        else
          'interactive'
    },

    data: -> model

    oncomplete: ->
      @fire('track-focus', document.activeElement)
      return

  })

# coffeelint: disable=max_line_length
template =
  """
  <div class="netlogo-model netlogo-display-{{# isVertical }}vertical{{ else }}horizontal{{/}}" style="min-width: {{width}}px;"
       tabindex="1" on-keydown="@this.fire('check-action-keys', @event)"
       on-focus="@this.fire('track-focus', @node)"
       on-blur="@this.fire('track-focus', @node)">
    <div id="modal-overlay" class="modal-overlay" style="{{# !isOverlayUp }}display: none;{{/}}" on-click="drop-overlay"></div>
    <div class="netlogo-display-vertical">
      <asyncDialog wareaHeight="{{height}}" wareaWidth="{{width}}"></asyncDialog>
      <helpDialog isOverlayUp="{{isOverlayUp}}" isVisible="{{isHelpVisible}}" stateName="{{stateName}}" wareaHeight="{{height}}" wareaWidth="{{width}}"></helpDialog>
      <contextMenu></contextMenu>
      <label class="netlogo-speed-slider{{#isEditing}} interface-unlocked{{/}}">
        <span class="netlogo-label">model speed</span>
        <input type="range" min=-1 max=1 step=0.01 value="{{speed}}"{{#isEditing}} disabled{{/}} />
        <tickCounter isVisible="{{primaryView.showTickCounter}}"
                     label="{{primaryView.tickCounterLabel}}" value="{{ticks}}" />
      </label>
      <div style="position: relative; width: {{width}}px; height: {{height}}px"
           class="netlogo-widget-container{{#isEditing}} interface-unlocked{{/}}"
           on-contextmenu="@this.fire('show-context-menu', { component: @this }, @event)"
           on-click="@this.fire('deselect-widgets', @event)" on-dragover="hail-satan">
        <resizer isEnabled="{{isEditing}}" isVisible="{{isResizerVisible}}" />
        {{#widgetObj:key}}
          {{# type ===    'textBox'  }}    <labelWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type === 'hnwTextBox'  }} <hnwLabelWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type ===    'view'     }}    <viewWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" ticks="{{ticks}}" /> {{/}}
          {{# type === 'hnwView'     }} <hnwViewWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" ticks="{{ticks}}" /> {{/}}
          {{# type ===    'switch'   }}    <switchWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type === 'hnwSwitch'   }} <hnwSwitchWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'button'   }}    <buttonWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" ticksStarted="{{ticksStarted}}" procedures="{{metadata.procedures}}" errorClass="{{>errorClass}}" /> {{/}}
          {{# type === 'hnwButton'   }} <hnwButtonWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" ticksStarted="{{ticksStarted}}" procedures="{{metadata.procedures}}" /> {{/}}
          {{# type ===    'slider'   }}    <sliderWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" errorClass="{{>errorClass}}" /> {{/}}
          {{# type === 'hnwSlider'   }} <hnwSliderWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'chooser'  }}    <chooserWidget id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type === 'hnwChooser'  }} <hnwChooserWidget id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'monitor'  }}    <monitorWidget id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" metadata="{{metadata}}" errorClass="{{>errorClass}}" /> {{/}}
          {{# type === 'hnwMonitor'  }} <hnwMonitorWidget id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" metadata="{{metadata}}" /> {{/}}
          {{# type ===    'inputBox' }}    <inputWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type === 'hnwInputBox' }} <hnwInputWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'plot'     }}    <plotWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type === 'hnwPlot'     }} <hnwPlotWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type ===    'output'   }}    <outputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" text="{{outputWidgetOutput}}" /> {{/}}
          {{# type === 'hnwOutput'   }} <hnwOutputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" text="{{outputWidgetOutput}}" /> {{/}}
        {{/}}
      </div>
    </div>
    <input id="general-file-input" type="file" name="general-file" style="display: none;" />
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
