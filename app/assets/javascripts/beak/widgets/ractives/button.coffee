import RactiveWidget from "./widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
import { RactiveEditFormMultilineCode } from "./subcomponent/code-container.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import { RactiveEditFormLabeledInput } from "./subcomponent/labeled-input.js"

ButtonEditForm = EditForm.extend({

  data: -> {
    actionKey:      undefined # String
  , display:        undefined # String
  , isForever:      undefined # Boolean
  , source:         undefined # String
  , startsDisabled: undefined # Boolean
  , type:           undefined # String
  , oldSize:        undefined # Boolean
  }

  computed: { displayedType: { get: -> @_typeToDisplay(@get('type')) } }

  on: {
    'handle-action-key-press': ({ event: { key }, node }) ->
      if key isnt "Enter"
        node.value = ""
  }

  twoway: false

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formCode:     RactiveEditFormMultilineCode
  , formDropdown: RactiveEditFormDropdown
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  genProps: (form) ->
    key    = form.actionKey.value
    source = @findComponent('formCode').findComponent('codeContainer').get('code')
    {
                   actionKey: (if key.length is 1 then key.toUpperCase() else null)
    ,             buttonKind: @_displayToType(form.type.value)
    , disableUntilTicksStart: form.startsDisabled.checked
    ,                display: (if form.display.value isnt "" then form.display.value else undefined)
    ,                forever: form.forever.checked
    ,                 source: (if source isnt "" then source else undefined)
    ,                oldSize: form.oldSize.checked
    }

  partials: {

    title: "Button"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <div class="flex-row" style="align-items: center;">
        <formDropdown id="{{id}}-type" choices="['observer', 'turtles', 'patches', 'links']" name="type" label="Agent(s):" selected="{{displayedType}}" />
        <formCheckbox id="{{id}}-forever-checkbox" isChecked={{isForever}} labelText="Forever" name="forever" />
      </div>

      <spacer height="15px" />

      <formCheckbox id="{{id}}-start-disabled-checkbox" isChecked={{startsDisabled}} labelText="Disable until ticks start" name="startsDisabled" />

      <spacer height="15px" />

      <formCode id="{{id}}-source" name="source" value="{{source}}" label="Commands" />

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <labeledInput id="{{id}}-display" labelStr="Display name:" name="display" class="widget-edit-inputbox" type="text" value="{{display}}" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <label for="{{id}}-action-key">Action key:</label>
        <input  id="{{id}}-action-key" name="actionKey" type="text" value="{{actionKey}}"
                class="widget-edit-inputbox" style="text-transform: uppercase; width: 33px;"
                on-keypress="handle-action-key-press" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center; justify-content: space-between; margin-left: 4px; margin-right: 4px;">
        <formCheckbox id="{{id}}-old-size" isChecked="{{ oldSize }}" labelText="Use old widget sizing"
                    name="oldSize" />
      </div>
      """
    # coffeelint: enable=max_line_length

  }

  _displayToType: (display) ->
    { observer: "Observer" , turtles: "Turtle", patches: "Patch", links: "Link" }[display]

  _typeToDisplay: (type) ->
    { Observer: "observer", Turtle: "turtles" , Patch: "patches", Link: "links" }[type]

})

HNWButtonEditForm = ButtonEditForm.extend({

  data: -> {
    actionKey:      undefined # String
  , display:        undefined # String
  , isForever:      false     # Boolean
  , procedures:     undefined # Array[Procedure]
  , procName:       undefined # String
  , startsDisabled: false     # Boolean
  , type:           undefined # String
  , oldSize:        undefined # Boolean
  }

  computed: {
    procChoices: {
      get: ->
        @get('procedures').filter(
          (p) ->
            (not p.isReporter) and
            p.argCount is 0 and
            (p.isUseableByObserver or p.isUseableByTurtles)
        ).map(
          (p) ->
            p.name
        ).sort()
      set: ((->))
    }
  }

  genProps: (form) ->

    hnwProcName = form.procName.value

    buttonKind =
      if hnwProcName is ""
        "turtle-procedure"
      else
        if @get('procedures').find((p) -> p.name is hnwProcName).isUseableByTurtles
          "turtle-procedure"
        else
          "procedure"

    key = form.actionKey.value

    {              actionKey: (if key.length is 1 then key.toUpperCase() else null)
    ,             buttonKind
    , disableUntilTicksStart: false
    ,                display: (if form.display.value isnt "" then form.display.value else hnwProcName)
    ,                forever: false
    ,            hnwProcName
    ,                 source: undefined
    ,                oldSize: form.oldSize.checked
    }

  partials: {

    title: "Button"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <formDropdown id="{{id}}-proc-name" name="procName" selected="{{procName}}" choices="{{procChoices}}" label="Procedure" />

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <labeledInput id="{{id}}-display" labelStr="Display name:" name="display" class="widget-edit-inputbox" type="text" value="{{display}}" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <label for="{{id}}-action-key">Action key:</label>
        <input  id="{{id}}-action-key" name="actionKey" type="text" value="{{actionKey}}"
                class="widget-edit-inputbox" style="text-transform: uppercase; width: 33px;"
                on-keypress="handle-action-key-press" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center; justify-content: space-between; margin-left: 4px; margin-right: 4px;">
        <formCheckbox id="{{id}}-old-size" isChecked="{{ oldSize }}" labelText="Use old widget sizing"
                    name="oldSize" />
      </div>
      """
    # coffeelint: enable=max_line_length

  }

})

RactiveButton = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , errorClass:         undefined # String
  , ticksStarted:       undefined # Boolean
  , isRunning:          false     # Boolean
  }

  computed: {
    isEnabled: {
      get: ->
        if @get('isEditing')
          false
        else
          widget            = @get('widget')
          ticksAreStarted   = @get('ticksStarted')
          isAlwaysEnabled   = not widget.disableUntilTicksStart
          lastCompileFailed = not widget.compilation.success
          (ticksAreStarted or isAlwaysEnabled or lastCompileFailed)
    }
  }

  clickHandler: (_, ractive) ->
    if ractive.get('isEnabled')
      ractive.get('widget.run')()
    return

  oninit: ->
    @_super()

    @on('activate-button', (_) ->
      if @get('isEnabled')
        @clickHandler(_, this)
        widget = @get('widget')
        @fire('button-widget-clicked', widget.id, widget.display, widget.source, false, false)
      return
    )
    return

  on: {
    'forever-button-change': () ->
      isRunning = @get('isRunning')
      @set('widget.running', isRunning)
      widget = @get('widget')
      @fire('button-widget-clicked', widget.id, widget.display, widget.source, true, isRunning)
      return

    'handle-forever-button-keydown': (ctx) ->
      event = ctx.event
      if event.key is " " or event.key is "Enter"
        event.preventDefault()
        isRunning = not @get('isRunning')
        @set('isRunning', isRunning)
        @fire('forever-button-change')
      return
  }

  observe: {
    'widget.running': (isRunning) ->
      @set('isRunning', isRunning)
      return
  }

  components: {
    editForm: ButtonEditForm
  }

  eventTriggers: ->
    {
      buttonKind: [@_weg.recompile]
    ,    forever: [@_weg.recompile]
    ,     source: [@_weg.recompile]
    }

  # (Widget) => Array[Any]
  getExtraNotificationArgs: () ->
    button = @get('widget')
    [button.display, button.source]

  minWidth:  35
  minHeight: 30

  # coffeelint: disable=max_line_length
  template:
    """
    {{>editorOverlay}}
    {{>button}}
    {{>editForm}}
    """

  partials: {

    button:
      """
      {{# widget.forever }}
        {{>foreverButton}}
      {{ else }}
        {{>standardButton}}
      {{/}}
      """

    editForm:
      """
      <editForm actionKey="{{widget.actionKey}}" display="{{widget.display}}"
                idBasis="{{id}}" isForever="{{widget.forever}}" source="{{widget.source}}"
                startsDisabled="{{widget.disableUntilTicksStart}}" type="{{widget.buttonKind}}" oldSize="{{widget.oldSize}}" />
      """

    standardButton:
      """
      <button id="{{id}}" type="button" style="{{dims}}" aria-label="{{ariaLabel}}" tabindex="{{#isEnabled}}{{tabindex}}{{else}}-1{{/}}"
              class="netlogo-widget netlogo-button netlogo-command{{#widget.oldSize}} old-size{{/}}{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}} {{classes}}"
              on-click="@this.fire('activate-button')" aria-disabled="{{!isEnabled}}">
        {{>buttonContext}}
        {{>label}}
        {{>actionKeyIndicator}}
      </button>
      """

    foreverButton:
      """
      <label id="{{id}}" style="{{dims}}" role="button" aria-disabled="{{!isEnabled}}" aria-label="{{ariaLabel}}"
             disabled="{{!isEnabled}}" aria-pressed="{{# isRunning }}true{{else}}false{{/}}" tabindex="{{#isEnabled}}{{tabindex}}{{else}}-1{{/}}"
             on-keydown="handle-forever-button-keydown"
             class="netlogo-widget netlogo-button netlogo-forever-button{{#widget.oldSize}} old-size{{/}}{{#isRunning}} netlogo-active{{/}} netlogo-command{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}} {{classes}}">
        {{>buttonContext}}
        {{>label}}
        {{>actionKeyIndicator}}
        <input type="checkbox" checked={{ isRunning }} on-change="forever-button-change" {{# !isEnabled }}disabled{{/}}/>
        <div class="netlogo-forever-icon"></div>
      </label>
      """

    buttonContext:
      """
      <div class="netlogo-button-agent-context">
      {{#if widget.buttonKind === "Turtle" }}
        T
      {{elseif widget.buttonKind === "Patch" }}
        P
      {{elseif widget.buttonKind === "Link" }}
        L
      {{/if}}
      </div>
      """

    label:
      """
      <span class="netlogo-label">{{widget.display || widget.source}}</span>
      """

    actionKeyIndicator:
      """
      {{# widget.actionKey }}
        <span class="netlogo-action-key {{# widget.hasFocus }}netlogo-focus{{/}}">
          {{widget.actionKey}}
        </span>
      {{/}}
      """

  }
  # coffeelint: enable=max_line_length

})

RactiveHNWButton = RactiveButton.extend({

  components: {
    editForm: HNWButtonEditForm
  }

  computed: {
    isEnabled: {
      get: -> (@get('ticksStarted') or (not @get('widget').disableUntilTicksStart)) and
              (not @get('isEditing'))
    }
  }

  clickHandler: (_, ractive) ->
    if ractive.get('isEnabled')
      procName = ractive.get('widget.hnwProcName')
      ractive.parent.fire('hnw-send-widget-message', 'button', procName)
    return

  partials: {
    editForm:
      """
      <editForm actionKey="{{widget.actionKey}}" display="{{widget.display}}"
                idBasis="{{id}}" isForever="{{widget.forever}}" procName="{{widget.hnwProcName}}"
                startsDisabled="{{widget.disableUntilTicksStart}}" type="{{widget.buttonKind}}"
                procedures="{{procedures}}" oldSize="{{widget.oldSize}}" />
      """
  }

})

export { RactiveButton, RactiveHNWButton }
