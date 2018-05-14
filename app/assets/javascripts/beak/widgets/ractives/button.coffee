ButtonEditForm = EditForm.extend({

  data: -> {
    actionKey:      undefined # String
  , display:        undefined # String
  , isForever:      undefined # Boolean
  , source:         undefined # String
  , startsDisabled: undefined # Boolean
  , type:           undefined # String
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
      """
    # coffeelint: enable=max_line_length

  }

  _displayToType: (display) ->
    { observer: "Observer" , turtles: "Turtle", patches: "Patch", links: "Link" }[display]

  _typeToDisplay: (type) ->
    { Observer: "observer", Turtle: "turtles" , Patch: "patches", Link: "links" }[type]

})

window.RactiveButton = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , errorClass:         undefined # String
  , ticksStarted:       undefined # Boolean
  }

  computed: {
    isEnabled: {
      get: -> (@get('ticksStarted') or (not @get('widget').disableUntilTicksStart)) and (not @get('isEditing'))
    }
  }

  oninit: ->
    @_super()
    @on('activate-button', (_, run) -> if @get('isEnabled') then run())

  components: {
    editForm: ButtonEditForm
  }

  eventTriggers: ->
    {
      buttonKind: [@_weg.recompile]
    ,     source: [@_weg.recompile]
    }

  minWidth:  35
  minHeight: 30

  # coffeelint: disable=max_line_length
  template:
    """
    {{>editorOverlay}}
    {{>button}}
    <editForm actionKey="{{widget.actionKey}}" display="{{widget.display}}"
              idBasis="{{id}}" isForever="{{widget.forever}}" source="{{widget.source}}"
              startsDisabled="{{widget.disableUntilTicksStart}}" type="{{widget.buttonKind}}" />
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

    standardButton:
      """
      <button id="{{id}}" type="button" style="{{dims}}"
              class="netlogo-widget netlogo-button netlogo-command{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}} {{classes}}"
              on-click="@this.fire('activate-button', @this.get('widget.run'))">
        {{>buttonContext}}
        {{>label}}
        {{>actionKeyIndicator}}
      </button>
      """

    foreverButton:
      """
      <label id="{{id}}" style="{{dims}}"
             class="netlogo-widget netlogo-button netlogo-forever-button{{#widget.running}} netlogo-active{{/}} netlogo-command{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}} {{classes}}">
        {{>buttonContext}}
        {{>label}}
        {{>actionKeyIndicator}}
        <input type="checkbox" checked={{ widget.running }} {{# !isEnabled }}disabled{{/}}/>
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
