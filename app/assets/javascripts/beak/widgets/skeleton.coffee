import { RactiveNote, RactiveHNWNote } from "./ractives/note.js"
import { RactiveInput, RactiveHNWInput } from "./ractives/input.js"
import { RactiveButton, RactiveHNWButton } from "./ractives/button.js"
import { RactiveView, RactiveHNWView } from "./ractives/view.js"
import { RactiveSlider, RactiveHNWSlider } from "./ractives/slider.js"
import { RactiveChooser, RactiveHNWChooser } from "./ractives/chooser.js"
import { RactiveMonitor, RactiveHNWMonitor } from "./ractives/monitor.js"
import RactiveToaster from "./ractives/toaster.js"
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
import RactiveTabWidget from "./ractives/tab.js"
import { keybinds } from "./accessibility/keybinds.js"
import { setSortingKeys } from "./accessibility/widgets.js"
import { ractiveAccessibleClickEvent, ractiveCopyEvent, ractivePasteEvent } from "./accessibility/events.js"

# (Element, Array[Widget], String, String,
#   Boolean, NlogoSource, String, Boolean, String, (String) => Boolean) => Ractive
generateRactiveSkeleton = (container, widgets, code, info,
  isReadOnly, source, workInProgressState, checkIsReporter) ->

  model = {
    checkIsReporter
  , code
  , consoleOutput:         ''
  , exportForm:            false
  , hasFocus:              false
  , workInProgressState
  , height:                0
  , hnwClients:            {}
  , hnwRoles:              {}
  , info
  , isEditing:             false
  , isHelpVisible:         false
  , isHNW:                 false
  , isHNWHost:             false
  , isHNWTicking:          false
  , isOverlayUp:           false
  , isReadOnly
  , isResizerVisible:      true
  , isStale:               false
  , isVertical:            true
  , lastCompiledCode:      code
  , lastCompileFailed:     false
  , lastDragX:             undefined
  , lastDragY:             undefined
  , metadata:              { globalVars: [], myVars: [], procedures: [] }
  , modelTitle:            source.getModelTitle()
  , outputWidgetOutput:    ''
  , primaryView:           undefined
  , someDialogIsOpen:      false
  , someEditFormIsOpen:    false
  , source
  , speed:                 0.0
  , ticks:                 "" # Remember, ticks initialize to nothing, not 0
  , ticksStarted:          false
  , widgetObj:             setSortingKeys(widgets.reduce(((acc, widget, index) -> acc[index] = widget; acc), {}))
  , width:                 0
  , keybinds:              keybinds
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

  Ractive.events.activateClick   = ractiveAccessibleClickEvent
  Ractive.events.copy            = ractiveCopyEvent
  Ractive.events.paste           = ractivePasteEvent

  Ractive.transitions.grow       = animateWithClass('growing')
  Ractive.transitions.shrink     = animateWithClass('shrinking')

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

    , spacer:           RactiveEditFormSpacer
    , customSlider:     RactiveCustomSlider
    , tab:              RactiveTabWidget
    , toaster:          RactiveToaster
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

  <toaster />

  <div class="netlogo-model netlogo-display-{{# isVertical }}vertical{{ else }}horizontal{{/}}" style="min-width: {{width}}px;"
       tabindex="0" on-keydown="@this.fire('check-action-keys', @event)"
       on-focus="@this.fire('track-focus', @node)"
       on-blur="@this.fire('track-focus', @node)">
    <div id="modal-overlay" class="modal-overlay" style="{{# !isOverlayUp }}display: none;{{/}}" on-click="drop-overlay"></div>

    <div class="netlogo-display-vertical" aria-label="NetLogo Model Application">

      <div class="netlogo-header">
        <div class="netlogo-subheader">
          <div class="netlogo-powered-by">
            <a href="https://netlogo.org">
              <svg class="netlogo-powered-by-image" viewBox="0 0 32 32" fill="none" role="img" alt="NetLogo Logo">
                <g clip-path="url(#clip0_6761_1992)">
                <rect x="32" y="32" width="32" height="32" transform="rotate(-180 32 32)" fill="#43B8FF"/>
                <mask id="mask0_6761_1992" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="1" y="0" width="30" height="30">
                <rect x="1.33301" y="0.666016" width="28.8347" height="28.8347" fill="#D9D9D9"/>
                </mask>
                <g mask="url(#mask0_6761_1992)">
                <path d="M9.16699 24.6673C7.37457 24.6673 5.84313 23.9779 4.57267 22.599C3.30222 21.2202 2.66699 19.5349 2.66699 17.5432C2.66699 15.8361 3.12987 14.315 4.05563 12.9799C4.98139 11.6448 6.4882 10.9495 7.98517 10.5775C8.4776 8.5639 9.7579 6.63784 10.9397 5.98129C12.5993 5.0593 17.2635 4.63493 18.4144 8.15385C19.2123 7.71233 21.2537 7.47356 22.4355 8.78676C22.9977 9.41147 23.9397 10.4317 23.9397 12.5473C25.2988 12.7223 26.4265 13.6748 27.3227 14.802C28.2189 15.9291 28.667 17.2478 28.667 18.7579C28.667 20.3994 28.1499 21.7947 27.1159 22.9438C26.0818 24.0928 24.8261 24.6673 23.3488 24.6673H9.16699Z" fill="#EEF5FF"/>
                </g>
                <g clip-path="url(#paint0_angular_6761_1992_clip_path)" data-figma-skip-parse="true"><g transform="matrix(0.00777778 3.09751e-10 -3.09751e-10 0.00777778 14.1107 16.334)"><foreignObject x="-1071.43" y="-1071.43" width="2142.86" height="2142.86"><div xmlns="http://www.w3.org/1999/xhtml" style="background:conic-gradient(from 90deg,rgba(200, 2, 0, 1) 0deg,rgba(195, 0, 0, 1) 0.0794891deg,rgba(191, 0, 0, 1) 116.448deg,rgba(223, 24, 0, 1) 127.48deg,rgba(223, 24, 0, 1) 235.378deg,rgba(255, 22, 0, 1) 240.998deg,rgba(243, 21, 0, 1) 359.438deg,rgba(200, 2, 0, 1) 360deg);height:100%;width:100%;opacity:1"></div></foreignObject></g></g><path d="M21.8885 16.334L10.7773 11.334L12.7218 16.334L10.7773 21.334L21.8885 16.334Z" data-figma-gradient-fill="{&#34;type&#34;:&#34;GRADIENT_ANGULAR&#34;,&#34;stops&#34;:[{&#34;color&#34;:{&#34;r&#34;:0.76470589637756348,&#34;g&#34;:0.0,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.00022080302005633712},{&#34;color&#34;:{&#34;r&#34;:0.75082629919052124,&#34;g&#34;:0.0,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.32346612215042114},{&#34;color&#34;:{&#34;r&#34;:0.87450981140136719,&#34;g&#34;:0.094117648899555206,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.35411190986633301},{&#34;color&#34;:{&#34;r&#34;:0.87450981140136719,&#34;g&#34;:0.094117648899555206,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.65382820367813110},{&#34;color&#34;:{&#34;r&#34;:1.0,&#34;g&#34;:0.086419761180877686,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.66943931579589844},{&#34;color&#34;:{&#34;r&#34;:0.95294117927551270,&#34;g&#34;:0.082352943718433380,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.99844002723693848}],&#34;stopsVar&#34;:[{&#34;color&#34;:{&#34;r&#34;:0.76470589637756348,&#34;g&#34;:0.0,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.00022080302005633712},{&#34;color&#34;:{&#34;r&#34;:0.75082629919052124,&#34;g&#34;:0.0,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.32346612215042114},{&#34;color&#34;:{&#34;r&#34;:0.87450981140136719,&#34;g&#34;:0.094117648899555206,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.35411190986633301},{&#34;color&#34;:{&#34;r&#34;:0.87450981140136719,&#34;g&#34;:0.094117648899555206,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.65382820367813110},{&#34;color&#34;:{&#34;r&#34;:1.0,&#34;g&#34;:0.086419761180877686,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.66943931579589844},{&#34;color&#34;:{&#34;r&#34;:0.95294117927551270,&#34;g&#34;:0.082352943718433380,&#34;b&#34;:0.0,&#34;a&#34;:1.0},&#34;position&#34;:0.99844002723693848}],&#34;transform&#34;:{&#34;m00&#34;:15.555554389953613,&#34;m01&#34;:-6.1950174767844146e-07,&#34;m02&#34;:6.3329005241394043,&#34;m10&#34;:6.1950112240083399e-07,&#34;m11&#34;:15.555551528930664,&#34;m12&#34;:8.5562067031860352},&#34;opacity&#34;:1.0,&#34;blendMode&#34;:&#34;NORMAL&#34;,&#34;visible&#34;:true}"/>
                </g>
                <defs>
                <clipPath id="paint0_angular_6761_1992_clip_path"><path d="M21.8885 16.334L10.7773 11.334L12.7218 16.334L10.7773 21.334L21.8885 16.334Z"/></clipPath><clipPath id="clip0_6761_1992">
                <rect width="32" height="32" rx="6" fill="white"/>
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
            <div class="netlogo-export-wrapper" aria-label="File Options" role="group">
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
            <div class="netlogo-export-wrapper" aria-label="Export Options" role="group">
              <span style="margin-right: 4px;">Export:</span>
              <button class="netlogo-ugly-button" on-click="export-nlogo"{{#isEditing}} disabled{{/}}>NetLogo</button>
              <button class="netlogo-ugly-button" on-click="export-html"{{#isEditing}} disabled{{/}}>HTML</button>
            </div>
          </div>
        {{/}}
      </div>

      <div class="netlogo-display-horizontal">

        <div id="authoring-lock" class="netlogo-toggle-container{{#!someDialogIsOpen}} enabled{{/}}"
             on-activateClick="toggle-interface-lock" tabindex="0" role="button" aria-pressed="{{isEditing}}">
          <div class="netlogo-interface-unlocker {{#isEditing}}interface-unlocked{{/}}"></div>
          <spacer width="5px" />
          <span class="netlogo-toggle-text">Mode: {{#isEditing}}Authoring{{else}}Interactive{{/}}</span>
        </div>

        <div id="tabs-position" tabindex="0" on-activateClick="toggle-orientation" role="button"
             aria-label="Toggle Tabs Position" aria-pressed="{{isVertical}}"
             aria-value="{{#isVertical}}Bottom{{else}}Right Side{{/}}"
             class="netlogo-toggle-container{{#!someDialogIsOpen}} enabled{{/}}">
          <div class="netlogo-model-orientation {{#isVertical}}vertical-display{{/}}"></div>
          <spacer width="5px" />
          <span class="netlogo-toggle-text">Commands and Code: {{#isVertical}}Bottom{{else}}Right Side{{/}}</span>
        </div>

        <label class="netlogo-speed-slider{{#isEditing}} interface-unlocked{{/}}" aria-label="Model Speed Slider"
               role="slider" aria-valuemin="-1" aria-valuemax="1" aria-valuenow="{{speed}}">
          <div class="netlogo-speed-slider-layout">
            <span class="netlogo-label">Model Speed</span>
            <div class="model-speed-input">
              <input type="range" min=-1 max=1 step=0.01 value="{{speed}}"
                {{#isEditing}} disabled{{/}} on-change="['speed-slider-changed', speed]" id="speed-slider-input" hidden />
              <button class="netlogo-beautiful-button" on-click="['onSpeedChange', -0.1]"
                {{#isEditing}} disabled{{/}} aria-label="Decrease Model Speed">-</button>
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
                {{#isEditing}} disabled{{/}} aria-label="Increase Model Speed">+</button>
            </div>
            <tickCounter isVisible="{{primaryView.showTickCounter}}"
              label="{{primaryView.tickCounterLabel}}" value="{{ticks}}" />
          </div>
        </label>

        <div style="display: flex; align-items: center; user-select: none; gap: 8px; flex: 1 1 auto; white-space: nowrap;"
             class="netlogo-help-keybind-hint{{#isEditing}} interface-unlocked{{/}}">
          <kbd>?</kbd> for shortcuts
        </div>
      </div>

      <asyncDialog wareaHeight="{{height}}" wareaWidth="{{width}}"></asyncDialog>
      <helpDialog keybindGroups="{{keybinds}}" isOverlayUp="{{isOverlayUp}}" isVisible="{{isHelpVisible}}" wareaHeight="{{height}}" wareaWidth="{{width}}"></helpDialog>
      <contextMenu></contextMenu>

      <div style="position: relative; width: {{width}}px; height: {{height}}px"
           class="netlogo-widget-container{{#isEditing}} interface-unlocked{{/}}"
           on-contextmenu="@this.fire('show-context-menu', { component: @this }, @event)"
           on-click="@this.fire('deselect-widgets', @event)" on-dragover="mosaic-killer-killer"
           aria-label="NetLogo Model Display Area" role="application">
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
      <tab name="console" title="Command Center" show="{{showConsole}}" scroll-block="center"
            on-toggle="['command-center-toggled', show]" focus-target=".netlogo-output-area">
        <console output="{{consoleOutput}}" isEditing="{{isEditing}}" checkIsReporter="{{checkIsReporter}}" />
      </tab>
      {{/}}
      <tab name="code" title="NetLogo Code" show="{{showCode}}"
            on-toggle="['model-code-toggled', show]" focus-target=".netlogo-code-tab">
        <codePane code='{{code}}' lastCompiledCode='{{lastCompiledCode}}' scroll-block="center"
                  lastCompileFailed='{{lastCompileFailed}}' isReadOnly='{{isReadOnly}}' />
      </tab>
      <tab name="info" title="Model Info" show="{{showInfo}}" scroll-target="#tab-info" scroll-block="center"
            on-toggle="['model-info-toggled', show]" focus-target=":is(.netlogo-info-markdown, .netlogo-info-editor)">
        <infotab rawText='{{info}}' isEditing='{{isEditing}}' />
      </tab>
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
