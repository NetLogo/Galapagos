window.RactiveButton = RactiveWidget.extend({

  data: -> {
    errorClass:   undefined # String
  , ticksStarted: undefined # Boolean
  }

  computed: {
    isEnabled: {
      get: -> @get('ticksStarted') or (not @get('widget').disableUntilTicksStart)
    }
  }

  oninit: ->
    @on('activateButton', (event, run) -> run())

  isolated: true

  # coffeelint: disable=max_line_length
  template:
    """
    {{>button}}
    {{>contextMenu}}
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
              on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
              class="netlogo-widget netlogo-button netlogo-command{{# !isEnabled }} netlogo-disabled{{/}} {{errorClass}}"
              type="button"
              style="{{dims}}"
              on-click="activateButton:{{widget.run}}"
              disabled={{ !isEnabled }}>
        {{>buttonContext}}
        {{>label}}
        {{>actionKeyIndicator}}
      </button>
      """

    foreverButton:
      """
      <label id="{{id}}"
             on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
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
      {{#if widget.buttonType === "TURTLE" }}
        T
      {{elseif widget.buttonType === "PATCH" }}
        P
      {{elseif widget.buttonType === "LINK" }}
        L
      {{/if}}
      </div>
      """

    contextMenu:
      """
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
        </ul>
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
