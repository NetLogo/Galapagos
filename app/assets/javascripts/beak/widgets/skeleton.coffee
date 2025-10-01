import { RactiveNote, RactiveHNWNote } from "./ractives/note.js"
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
import RactiveCustomSlider from "./ractives/subcomponent/custom-slider.js"

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

    , noteWidget:    RactiveNote
    , switchWidget:  RactiveSwitch
    , buttonWidget:  RactiveButton
    , sliderWidget:  RactiveSlider
    , chooserWidget: RactiveChooser
    , monitorWidget: RactiveMonitor
    , inputWidget:   RactiveInput
    , outputWidget:  RactiveOutputArea
    , plotWidget:    RactivePlot
    , viewWidget:    RactiveView

    , hnwNoteWidget:   RactiveHNWNote
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
    , customSlider:  RactiveCustomSlider

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

    on: {
      onSpeedChange: (context, delta) ->
        speed = @get('speed')
        newSpeed = Math.max(-1, Math.min(1, speed + delta))
        newSpeed = parseFloat(newSpeed.toFixed(2))
        @set('speed', newSpeed)
        @fire('speed-slider-changed', newSpeed)
    }

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
            <a href="https://netlogo.org">
              <svg class="netlogo-powered-by-image" viewBox="0 0 48 48" role="img">
                <g clip-path="url(#clip0_1191_6280)">
                  <rect width="48" height="48" fill="url(#paint0_linear_1191_6280)"/>
                  <mask id="mask0_1191_6280" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="2" y="1" width="44" height="44">
                    <rect x="2" y="1" width="43.252" height="43.252" fill="#D9D9D9"/>
                  </mask>
                  <g mask="url(#mask0_1191_6280)">
                    <path d="M13.75 37C11.0614 37 8.7642 35.9659 6.85852 33.8976C4.95284 31.8293 4 29.3014 4 26.3139C4 23.7532 4.69432 21.4715 6.08295 19.4689C7.47159 17.4663 9.73182 16.4233 11.9773 15.8652C12.7159 12.8449 14.6364 9.95578 16.4091 8.97096C18.8985 7.58798 25.8948 6.95142 27.6211 12.2298C28.818 11.5675 31.88 11.2094 33.6527 13.1792C34.4961 14.1162 35.9091 15.6466 35.9091 18.8199C37.9477 19.0825 39.6392 20.5112 40.9835 22.202C42.3278 23.8927 43 25.8707 43 28.1359C43 30.5982 42.2244 32.6911 40.6733 34.4146C39.1222 36.1382 37.2386 37 35.0227 37H13.75Z" fill="#BBD7FF"/>
                  </g>
                  <path d="M19.8371 25.266L14.4669 16.1838L17.8471 25.1211C17.8913 25.2379 17.8937 25.3665 17.8539 25.4849L14.808 34.5415L19.8371 25.266Z" fill="url(#paint1_linear_1191_6280)"/>
                  <path d="M19.6201 25.1302L14.4259 16.1209C14.294 15.8922 14.5343 15.6295 14.7738 15.7403L34.758 24.9887L19.8595 25.2655C19.761 25.2674 19.6693 25.2155 19.6201 25.1302Z" fill="url(#paint2_linear_1191_6280)"/>
                  <path d="M19.6255 25.4098L14.7696 34.6059C14.6463 34.8393 14.8961 35.0929 15.1314 34.9733L34.758 24.9887L19.8595 25.2655C19.761 25.2674 19.6715 25.3227 19.6255 25.4098Z" fill="url(#paint3_linear_1191_6280)"/>
                </g>
                <defs>
                  <linearGradient id="paint0_linear_1191_6280" x1="70.2667" y1="-23.6" x2="30" y2="30.8" gradientUnits="userSpaceOnUse">
                    <stop stop-color="#103E7D"/>
                    <stop offset="0.465" stop-color="#7FBFFF"/>
                    <stop offset="1" stop-color="#5E92F3"/>
                  </linearGradient>
                  <linearGradient id="paint1_linear_1191_6280" x1="27.5" y1="22.5" x2="12.1082" y2="27.2506" gradientUnits="userSpaceOnUse">
                    <stop stop-color="#F31500"/>
                    <stop offset="1" stop-color="#BB1101"/>
                  </linearGradient>
                  <linearGradient id="paint2_linear_1191_6280" x1="27.5" y1="22.5" x2="12.1082" y2="27.2506" gradientUnits="userSpaceOnUse">
                    <stop stop-color="#F31500"/>
                    <stop offset="1" stop-color="#BB1101"/>
                  </linearGradient>
                  <linearGradient id="paint3_linear_1191_6280" x1="27.5" y1="22.5" x2="12.1082" y2="27.2506" gradientUnits="userSpaceOnUse">
                    <stop stop-color="#F31500"/>
                    <stop offset="1" stop-color="#BB1101"/>
                  </linearGradient>
                  <clipPath id="clip0_1191_6280">
                  <rect width="48" height="48" rx="9.06667" fill="white"/>
                  </clipPath>
                </defs>
              </svg>
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

        <label class="netlogo-speed-slider{{#isEditing}} interface-unlocked{{/}}">
          <div class="netlogo-speed-slider-layout">
            <span class="netlogo-label">Model Speed</span>
            <div class="model-speed-input">
              <input type="range" min=-1 max=1 step=0.01 value="{{speed}}"
                {{#isEditing}} disabled{{/}} on-change="['speed-slider-changed', speed]" id="speed-slider-input" hidden />
              <button class="netlogo-beautiful-button" on-click="['onSpeedChange', -0.1]"
                {{#isEditing}} disabled{{/}}>-</button>
              <customSlider
                id="speed-slider-input-interface"
                min="{{-1}}"
                max="{{1}}"
                step="{{0.01}}"
                value="{{speed}}"
                snapTo="0"
                snapTolerance="4.5"
                inputFor="speed-slider-input"
                isEnabled="{{!isEditing}}"
                class="model-speed-slider-interface"
              />
              <button class="netlogo-beautiful-button" on-click="['onSpeedChange', 0.1]"
                {{#isEditing}} disabled{{/}}>+</button>
            </div>
            <tickCounter isVisible="{{primaryView.showTickCounter}}"
              label="{{primaryView.tickCounterLabel}}" value="{{ticks}}" />
          </div>
        </label>

      </div>

      <asyncDialog wareaHeight="{{height}}" wareaWidth="{{width}}"></asyncDialog>
      <helpDialog isOverlayUp="{{isOverlayUp}}" isVisible="{{isHelpVisible}}" stateName="{{stateName}}" wareaHeight="{{height}}" wareaWidth="{{width}}"></helpDialog>
      <contextMenu></contextMenu>

      <div style="position: relative; width: {{width}}px; height: {{height}}px"
           class="netlogo-widget-container{{#isEditing}} interface-unlocked{{/}}"
           on-contextmenu="@this.fire('show-context-menu', { component: @this }, @event)"
           on-click="@this.fire('deselect-widgets', @event)" on-dragover="mosaic-killer-killer">
        <resizer isEnabled="{{isEditing}}" isVisible="{{isResizerVisible}}" />
        {{#widgetObj:key}}
          {{# type ===    'textBox'  }}    <noteWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type === 'hnwTextBox'  }} <hnwNoteWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type ===    'view'     }}    <viewWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" ticks="{{ticks}}" /> {{/}}
          {{# type === 'hnwView'     }} <hnwViewWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" ticks="{{ticks}}" /> {{/}}
          {{# type ===    'switch'   }}    <switchWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type === 'hnwSwitch'   }} <hnwSwitchWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'button'   }}    <buttonWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" ticksStarted="{{ticksStarted}}" procedures="{{metadata.procedures}}" errorClass="{{>errorClass}}" /> {{/}}
          {{# type === 'hnwButton'   }} <hnwButtonWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" ticksStarted="{{ticksStarted}}" procedures="{{metadata.procedures}}" /> {{/}}
          {{# type ===    'slider'   }}    <sliderWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" errorClass="{{>errorClass}}" /> {{/}}
          {{# type === 'hnwSlider'   }} <hnwSliderWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'chooser'  }}    <chooserWidget id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type === 'hnwChooser'  }} <hnwChooserWidget id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'monitor'  }}    <monitorWidget id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" metadata="{{metadata}}" errorClass="{{>errorClass}}" /> {{/}}
          {{# type === 'hnwMonitor'  }} <hnwMonitorWidget id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" metadata="{{metadata}}" /> {{/}}
          {{# type ===    'inputBox' }}    <inputWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type === 'hnwInputBox' }} <hnwInputWidget   id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" breedVars="{{metadata.myVars}}" /> {{/}}
          {{# type ===    'plot'     }}    <plotWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" /> {{/}}
          {{# type === 'hnwPlot'     }} <hnwPlotWidget    id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" procedures="{{metadata.procedures}}" /> {{/}}
          {{# type ===    'output'   }}    <outputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" text="{{outputWidgetOutput}}" /> {{/}}
          {{# type === 'hnwOutput'   }} <hnwOutputWidget  id="{{>widgetID}}" isEditing="{{isEditing}}" x="{{x}}" width="{{width}}" y="{{y}}" height="{{height}}" widget={{this}} isHNW="{{isHNW}}" text="{{outputWidgetOutput}}" /> {{/}}
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
