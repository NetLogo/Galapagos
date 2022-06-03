import { RactiveLabel, RactiveHNWLabel } from "./ractives/label.js"
import { RactiveInput, RactiveHNWInput } from "./ractives/input.js"
import { RactiveButton, RactiveHNWButton } from "./ractives/button.js"
import { RactiveView, RactiveHNWView } from "./ractives/view.js"
import { RactiveSlider, RactiveHNWSlider } from "./ractives/slider.js"
import { RactiveChooser, RactiveHNWChooser } from "./ractives/chooser.js"
import { RactiveMonitor, RactiveHNWMonitor } from "./ractives/monitor.js"
import RactiveModelCodeComponent from "./ractives/code-editor.js"
import { RactiveSwitch, RactiveHNWSwitch } from "./ractives/switch.js"
import RactiveHelpDialog from "./ractives/help-dialog.js"
import RactiveConsoleWidget from "./ractives/console.js"
import { RactiveOutputArea, RactiveHNWOutputArea } from "./ractives/output.js"
import RactiveInfoTabWidget from "./ractives/info.js"
import RactiveModelTitle from "./ractives/title.js"
import RactiveStatusPopup from "./ractives/status-popup.js"
import { RactivePlot, RactiveHNWPlot } from "./ractives/plot.js"
import RactiveResizer from "./ractives/resizer.js"
import RactiveAsyncUserDialog from "./ractives/async-user-dialog.js"
import RactiveContextMenu from "./ractives/context-menu.js"
import RactiveEditFormSpacer from "./ractives/subcomponent/spacer.js"
import RactiveTickCounter from "./ractives/subcomponent/tick-counter.js"

# (Element, Array[Widget], String, String,
#   Boolean, NlogoSource, String, Boolean, String, (String) => Boolean) => Ractive
generateRactiveSkeleton = (container, widgets, code, info,
  isReadOnly, source, workInProgressState, checkIsReporter) ->

  model = {
    checkIsReporter
  , code
  , consoleOutput:        ''
  , exportForm:           false
  , hasFocus:             false
  , workInProgressState
  , height:               0
  , hnwClients:           {}
  , hnwRoles:             {}
  , info
  , isEditing:            false
  , isHelpVisible:        false
  , isHNW:                false
  , isHNWHost:            false
  , isHNWTicking:         false
  , isOverlayUp:          false
  , isReadOnly
  , isResizerVisible:     true
  , isStale:              false
  , isVertical:           true
  , lastCompiledCode:     code
  , lastCompileFailed:    false
  , lastDragX:            undefined
  , lastDragY:            undefined
  , metadata:             { globalVars: [], myVars: [], procedures: [] }
  , modelTitle:           source.getModelTitle()
  , outputWidgetOutput:   ''
  , primaryView:          undefined
  , someDialogIsOpen:     false
  , someEditFormIsOpen:   false
  , source
  , speed:                0.0
  , ticks:                "" # Remember, ticks initialize to nothing, not 0
  , ticksStarted:         false
  , widgetObj:            widgets.reduce(((acc, widget, index) -> acc[index] = widget; acc), {})
  , width:                0
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
    , statusPopup:   RactiveStatusPopup
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

      isHNWJoiner: ->
        @get('isHNW') is true and @get('isHNWHost') is false

      stateName: ->
        if @get('isEditing')
          if @get('someEditFormIsOpen')
            'authoring - editing widget'
          else
            'authoring - plain'
        else
          'interactive'

      isRevertable: ->
        not @get('isEditing') and @get('hasWorkInProgress')

      disableWorkInProgress: ->
        @get('workInProgressState') is 'disabled'

      hasWorkInProgress: ->
        @get('workInProgressState') is 'enabled-with-wip'

      hasRevertedWork: ->
        @get('workInProgressState') is 'enabled-with-reversion'

    },

    data: -> model

    oncomplete: ->
      @fire('track-focus', document.activeElement)
      return

  })

# coffeelint: disable=max_line_length
template =
  """
  <statusPopup
    hasWorkInProgress={{hasWorkInProgress}}
    isSessionLoopRunning={{isSessionLoopRunning}}
    sourceType={{source.type}}
    />

  <div class="netlogo-model netlogo-display-{{# isVertical }}vertical{{ else }}horizontal{{/}}" style="min-width: {{width}}px;"
       tabindex="1" on-keydown="@this.fire('check-action-keys', @event)"
       on-focus="@this.fire('track-focus', @node)"
       on-blur="@this.fire('track-focus', @node)">
    <div id="modal-overlay" class="modal-overlay" style="{{# !isOverlayUp }}display: none;{{/}}" on-click="drop-overlay"></div>

    <div class="netlogo-display-vertical">

      <div class="netlogo-header">
        <div class="netlogo-subheader">
          <div class="netlogo-powered-by">
            <a href="http://ccl.northwestern.edu/netlogo/">
              <img style="vertical-align: middle;" alt="NetLogo" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAANcSURBVHjarJRdaFxFFMd/M/dj7252uxubKms+bGprVyIVbNMWWqkQqtLUSpQWfSiV+oVFTcE3DeiDgvoiUSiCYLH2oVoLtQ+iaaIWWtE2FKGkkSrkq5svN+sm7ma/7p3x4W42lEbjQw8MM8yc87/nzPnNFVprbqWJXyMyXuMqx1Ni6N3ny3cX8tOHNLoBUMvESoFI2Xbs4zeO1lzREpSrMSNS1zkBDv6uo1/noz1H7mpvS4SjprAl2AZYEqzKbEowBAgBAkjPKX2599JjT7R0bj412D0JYNplPSBD1G2SmR/e6u1ikEHG2vYiGxoJmxAyIGSCI8GpCItKimtvl2JtfGujDNkX6epuAhCjNeAZxM1ocPy2Qh4toGQ5DLU+ysiuA2S3P0KgJkjAgEAlQylAA64CG/jlUk6//ng4cNWmLK0yOPNMnG99Rs9LQINVKrD+wmke7upg55PrWP3eYcwrlykpKCkoelDy/HVegQhoABNAepbACwjOt72gZkJhypX70YDWEEklue+rbnYc2MiGp1upPfYReiJJUUG58gFXu4udch1wHcjFIgy0HyIjb2yvBpT2F6t+6+f+D15lW8c9JDo7iPSdgVIRLUqL2AyHDQAOf9hfbqxvMF98eT3RuTS1avHyl+Stcphe2chP9+4k/t3RbXVl3W+Ws17FY56/w3VcbO/koS/eZLoAqrQMxADZMTYOfwpwoWjL4+bCYcgssMqGOzPD6CIkZ/3SxTJ0ayFIN6/BnBrZb2XdE1JUgkJWkfrUNRJnPyc16zsbgPyXIUJBpvc+y89nk/S8/4nek3NPGeBWMwzGvhUPnP6RubRLwfODlqqx3LSCyee2MnlwMwA2RwgO5qouVcHmksUdJweYyi8hZkrUjgT5t/ejNq0jBsSqNWsKyT9uFtxw7Bs585d3g46KOeT2bWHmtd14KyP+5mzqpsYU3OyioACMhGiqPTMocsrHId9cy9BLDzKxq8X3ctMwlV6yKSHL4fr4dd0DeQBTBUgUkvpE1kVPbqkX117ZzuSaFf4zyfz5n9A4lk0yNU7vyb7jTy1kmFGipejKvh6h9n0W995ZPTu227hqmCz33xXgFV1v9NzI96NfjndWt7XWCB/7BSICFWL+j3lAofpCtfYFb6X9MwCJZ07mUsXRGwAAAABJRU5ErkJggg=="/>
              <span style="font-size: 16px;">powered by NetLogo</span>
            </a>
          </div>
        </div>
        <editableTitle
          title="{{modelTitle}}"
          isEditing="{{isEditing}}"
          hasWorkInProgress="{{hasWorkInProgress}}"
          />
        {{# !isReadOnly }}
          <div class="flex-column" style="align-items: flex-end; user-select: none;">
            <div class="netlogo-export-wrapper">
              <span style="margin-right: 4px;">File:</span>
              <button class="netlogo-ugly-button" on-click="open-new-file"{{#isEditing}} disabled{{/}}>New</button>
              {{#!disableWorkInProgress}}
                {{#!hasRevertedWork}}
                  <button class="netlogo-ugly-button" on-click="revert-wip"{{#!isRevertable}} disabled{{/}}>Revert to Original</button>
                {{else}}
                  <button class="netlogo-ugly-button" on-click="undo-revert"{{#isEditing}} disabled{{/}}>Undo Revert</button>
                {{/}}
              {{/}}
            </div>
            <div class="netlogo-export-wrapper">
              <span style="margin-right: 4px;">Export:</span>
              <button class="netlogo-ugly-button" on-click="export-nlogo"{{#isEditing}} disabled{{/}}>NetLogo</button>
              <button class="netlogo-ugly-button" on-click="export-html"{{#isEditing}} disabled{{/}}>HTML</button>
            </div>
          </div>
        {{/}}
      </div>

      <div class="netlogo-display-horizontal">

        <div id="authoring-lock" class="netlogo-toggle-container{{#!someDialogIsOpen}} enabled{{/}}" on-click="toggle-interface-lock">
          <div class="netlogo-interface-unlocker {{#isEditing}}interface-unlocked{{/}}"></div>
          <spacer width="5px" />
          <span class="netlogo-toggle-text">Mode: {{#isEditing}}Authoring{{else}}Interactive{{/}}</span>
        </div>

        <div id="tabs-position" class="netlogo-toggle-container{{#!someDialogIsOpen}} enabled{{/}}" on-click="toggle-orientation">
          <div class="netlogo-model-orientation {{#isVertical}}vertical-display{{/}}"></div>
          <spacer width="5px" />
          <span class="netlogo-toggle-text">Commands and Code: {{#isVertical}}Bottom{{else}}Right Side{{/}}</span>
        </div>
      </div>

      <asyncDialog wareaHeight="{{height}}" wareaWidth="{{width}}"></asyncDialog>
      <helpDialog isOverlayUp="{{isOverlayUp}}" isVisible="{{isHelpVisible}}" stateName="{{stateName}}" wareaHeight="{{height}}" wareaWidth="{{width}}"></helpDialog>
      <contextMenu></contextMenu>

      <label class="netlogo-speed-slider{{#isEditing}} interface-unlocked{{/}}">
        <span class="netlogo-label">model speed</span>
        <input type="range" min=-1 max=1 step=0.01 value="{{speed}}"{{#isEditing}} disabled{{/}} on-change="['speed-slider-changed', speed]" />
        <tickCounter isVisible="{{primaryView.showTickCounter}}"
                     label="{{primaryView.tickCounterLabel}}" value="{{ticks}}" />
      </label>

      <div style="position: relative; width: {{width}}px; height: {{height}}px"
           class="netlogo-widget-container{{#isEditing}} interface-unlocked{{/}}"
           on-contextmenu="@this.fire('show-context-menu', { component: @this }, @event)"
           on-click="@this.fire('deselect-widgets', @event)" on-dragover="mosaic-killer-killer">
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
          {{# type === 'hnwPlot'     }} <hnwPlotWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" procedures="{{metadata.procedures}}" /> {{/}}
          {{# type ===    'output'   }}    <outputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" text="{{outputWidgetOutput}}" /> {{/}}
          {{# type === 'hnwOutput'   }} <hnwOutputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" left="{{left}}" right="{{right}}" top="{{top}}" bottom="{{bottom}}" widget={{this}} isHNW="{{isHNW}}" text="{{outputWidgetOutput}}" /> {{/}}
        {{/}}
      </div>

    </div>

    <div class="netlogo-tab-area" style="min-width: {{Math.min(width, 500)}}px; max-width: {{Math.max(width, 500)}}px">
      {{# !isReadOnly }}
      <label class="netlogo-tab{{#showConsole}} netlogo-active{{/}}">
        <input id="console-toggle" type="checkbox" checked="{{ showConsole }}" on-change="['command-center-toggled', showConsole]"/>
        <span class="netlogo-tab-text">Command Center</span>
      </label>
      {{#showConsole}}
        <console output="{{consoleOutput}}" isEditing="{{isEditing}}" checkIsReporter="{{checkIsReporter}}" />
      {{/}}
      {{/}}
      <label class="netlogo-tab{{#showCode}} netlogo-active{{/}}">
        <input id="code-tab-toggle" type="checkbox" checked="{{ showCode }}" on-change="['model-code-toggled', showCode]" />
        <span class="netlogo-tab-text{{#lastCompileFailed}} netlogo-widget-error{{/}}">NetLogo Code</span>
      </label>
      {{#showCode}}
        <codePane code='{{code}}' lastCompiledCode='{{lastCompiledCode}}' lastCompileFailed='{{lastCompileFailed}}' isReadOnly='{{isReadOnly}}' />
      {{/}}
      <label class="netlogo-tab{{#showInfo}} netlogo-active{{/}}">
        <input id="info-toggle" type="checkbox" checked="{{ showInfo }}" on-change="['model-info-toggled', showInfo]" />
        <span class="netlogo-tab-text">Model Info</span>
      </label>
      {{#showInfo}}
        <infotab rawText='{{info}}' isEditing='{{isEditing}}' />
      {{/}}
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
    netlogo-{{type}}-{{key}}
    """

}
# coffeelint: enable=max_line_length

export default generateRactiveSkeleton
