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

  oninit: ->
    @_super()
    @on('handleActionKeyPress'
    , ({ node }) ->
        node.value = ""
    )

  twoway: false

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formCode:     RactiveEditFormCodeContainer
  , formDropdown: RactiveEditFormDropdown
  , spacer:       RactiveEditFormSpacer
  }

  validate: (form) ->
    key = form.actionKey.value
    {
      triggers: {
        buttonKind: [WidgetEventGenerators.recompile]
      ,     source: [WidgetEventGenerators.recompile]
      }
    , values: {
                     actionKey: (if key.length is 1 then key.toUpperCase() else null)
      ,             buttonKind: @_displayToType(form.type.value)
      , disableUntilTicksStart: form.startsDisabled.checked
      ,                display: (if form.display.value isnt "" then form.display.value else undefined)
      ,                forever: form.forever.checked
      ,                 source: @findComponent('formCode').findComponent('codeContainer').get('code')
      }
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
        <label for="{{id}}-display">Display name:</label>
        <input  id="{{id}}-display" name="display" type="text" value="{{display}}"
                style="flex-grow: 1; font-size: 20px; height: 26px; margin-left: 10px; padding: 4px;" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <label for="{{id}}-action-key">Action key:</label>
        <input  id="{{id}}-action-key" name="actionKey" type="text" value="{{actionKey}}"
                style="font-size: 20px; height: 26px; margin-left: 10px; padding: 4px;
                       text-transform: uppercase; width: 30px;"
                on-keypress="handleActionKeyPress" />
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
  , errorClass:   undefined # String
  , ticksStarted: undefined # Boolean
  }

  computed: {
    isEnabled: {
      get: -> @get('ticksStarted') or (not @get('widget').disableUntilTicksStart)
    }
  }

  oninit: ->
    @_super()
    @on('activateButton', (_, run) -> if @get('isEnabled') then run())

  components: {
    editForm: ButtonEditForm
  }

  # coffeelint: disable=max_line_length
  template:
    """
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
      <button id="{{id}}"
              on-contextmenu="@this.fire('showContextMenu', @event)"
              class="netlogo-widget netlogo-button netlogo-command{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}}"
              type="button"
              style="{{dims}}"
              on-click="@this.fire('activateButton', @this.get('widget.run'))">
        {{>buttonContext}}
        {{>label}}
        {{>actionKeyIndicator}}
      </button>
      """

    foreverButton:
      """
      <label id="{{id}}"
             on-contextmenu="@this.fire('showContextMenu', @event)"
             class="netlogo-widget netlogo-button netlogo-forever-button{{#widget.running}} netlogo-active{{/}} netlogo-command{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}}"
             style="{{dims}}">
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
