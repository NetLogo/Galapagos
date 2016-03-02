window.RactiveButton = Ractive.extend({
  data: {
    dims:         undefined # String
  , id:           undefined # String
  , widget:       undefined # ButtonWidget
  , errorClass:   undefined # String
  , ticksStarted: undefined # Boolean
  }

  oninit: ->
    @on('activateButton', (event, run) -> run())

  isolated: true

  # coffeelint: disable=max_line_length
  template:
    """
    {{# widget.forever }}
      {{>foreverButton}}
    {{ else }}
      {{>standardButton}}
    {{/}}
    """

  partials: {

    standardButton:
      """
      <button id="{{id}}"
              class="netlogo-widget netlogo-button netlogo-command {{# !ticksStarted && widget.disableUntilTicksStart }}netlogo-disabled{{/}} {{errorClass}}"
              type="button"
              style="{{dims}}"
              on-click="activateButton:{{widget.run}}"
              disabled={{ !ticksStarted && widget.disableUntilTicksStart }}>
        {{>buttonContext}}
        <span class="netlogo-label">{{widget.display || widget.source}}</span>
        {{# widget.actionKey }}
        <span class="netlogo-action-key {{# widget.hasFocus }}netlogo-focus{{/}}">
          {{widget.actionKey}}
        </span>
        {{/}}
      </button>
      """

    foreverButton:
      """
      <label id="{{id}}"
             class="netlogo-widget netlogo-button netlogo-forever-button {{#widget.running}}netlogo-active{{/}} netlogo-command {{# !ticksStarted && widget.disableUntilTicksStart }}netlogo-disabled{{/}} {{errorClass}}"
             style="{{dims}}">
        {{>buttonContext}}
        <input type="checkbox" checked={{ widget.running }} {{# !ticksStarted && widget.disableUntilTicksStart }}disabled{{/}}/>
        <span class="netlogo-label">{{widget.display || widget.source}}</span>
        {{# widget.actionKey }}
        <span class="netlogo-action-key {{# widget.hasFocus }}netlogo-focus{{/}}">
          {{widget.actionKey}}
        </span>
        {{/}}
        <div class="netlogo-forever-icon"></div>
      </label>
      """

  buttonContext:
    """
    <div class="netlogo-button-agent-context">
    {{#if buttonType === "TURTLE" }}
      T
    {{elseif buttonType === "PATCH" }}
      P
    {{elseif buttonType === "LINK" }}
      L
    {{/if}}
    </div>
    """

  }
  # coffeelint: enable=max_line_length

})
