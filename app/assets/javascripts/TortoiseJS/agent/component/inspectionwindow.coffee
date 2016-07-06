TurtleReadOnlies = {
  who: true
}

PatchReadOnlies = {
  pxcor: true
, pycor: true
}

LinkReadOnlies = {
  end1: true
, end2: true
}

VarInput = RactiveNetLogoCodeInput.extend({

  data: -> {
    varName: undefined # String
  }

  isolated: true

  setInput: (input) ->
    @set('input', input)

  _wrapInput: (input) ->
    "set #{@get('varName')} (#{input})"

})

VarRow = Ractive.extend({

  data: -> {
    agent:   undefined # Agent
    id:      undefined # String
    varName: undefined # String
  }

  components: {
    codeInput: VarInput
  }

  computed: {
    agentName:  '${agent}.toString()'
  , isReadOnly: 'this._getReadOnlyBundle()[${varName}] === true'
  , value:      'Dump(${agent}.getVariable(${varName}), true)'
  }

  isolated: true

  twoway: false

  _getReadOnlyBundle: ->
    type = NLType(@get('agent'))
    if type.isTurtle() then TurtleReadOnlies else if type.isLink() then LinkReadOnlies else PatchReadOnlies

  oninit: ->
    @on('codeInput.run-code'
    , (code) ->
        @fire('run-code', code)
        @fire('refresh-value')
    )

    @on('refresh-value'
    , =>
        value = @get('agent').getVariable(@get('agent'))
        @findComponent('codeInput').setInput(Dump(value, true))
    )

  template:
    """
    <div class="flex-row" style="align-items: center;">
      <label for="{{id}}-input" class="inspection-window-var-label" title="{{varName}}">{{varName}}</label>
      <div style="flex-grow: 1;">
        {{ #isReadOnly }}
          <input id="{{id}}-input" class="widget-edit-text widget-edit-input"
                 style="padding-right: 6px; text-align: right;" value="{{value}}" disabled />
        {{else}}
          <codeInput id="{{id}}-input" class="netlogo-inspector-var-editor"
                     style="padding-right: 6px; text-align: right;"
                     initialAskee="{{agentName}}" initialInput="{{value}}" varName="{{varName}}" />
        {{/}}
      </div>
    </div>
    """

})

window.RactiveInspectionWindow = RactiveModalDialog.extend({

  data: -> {
    agent: undefined       # Agent
    style: "width: 300px;" # String
  }

  computed: {
    agentName: '${agent}.toString()'
    id:        '${agentName}.replace(/[ )(]/g, "")'
  }

  isolated: true

  components: {
    codeEditor:              RactiveEditFormCodeContainer
  , inspectionCommandCenter: RactiveNetLogoCodeInput
  , varRow:                  VarRow
  }

  _draw: ->
    context = @find("##{@get('id')}-canvas").getContext("2d")
    context.fillStyle = "white"
    context.font = "bold 30px Arial"
    context.fillText("Unimplemented", 40, 80)

  oninit: ->
    @_super()

    @on('watchAgent', -> @get('agent').watchMe(); return)

    @on('handleZoom'
    , ({ original: { target: { value } } }) ->
        #scale = Math.pow(2, value)
        #console.log(scale)
        #canvas  = @find("##{@get('id')}-canvas")
        #context = canvas.getContext("2d")
        #context.clearRect(0, 0, canvas.width, canvas.height)
        #context.translate(canvas.height / 2, canvas.width / 2)
        #context.scale(scale, scale)
        #@_draw()
        return
    )

  oncomplete: ->
    @_super()
    @_draw()

  partials: {

    innerContent:
      """
      {{>title}}
      {{>viewBox}}
      {{>subViewStrip}}
      {{>variables}}
      {{>commandCenter}}
      """

    title:
      """
      <div class="netlogo-dialog-title">{{agent.toString().replace(/[)(]/g, '')}}</div>
      """

    viewBox:
      """
      <canvas id="{{id}}-canvas" style="background-color: black; height: 300px; width: 300px;"></canvas>
      """

    subViewStrip:
      """
      <div class="flex-row" style="height: 35px; margin: 8px 0;">
        <input style="flex-grow: 1; font-size: 20px; font-weight: bold;" type="button"
               value="watch-me" on-click="watchAgent" />
        <input style="flex-grow: 1" type="range" on-input="handleZoom"
               min="-10" max="10" step="1" value="0" disabled />
      </div>
      """

    variables:
      """
      <div>
        {{# agent.varNames() }}
          <varRow agent="{{agent}}" id="{{id}}" varName="{{.}}" />
        {{/}}
      </div>
      """

    commandCenter:
      """
      <inspectionCommandCenter initialAskee="{{agentName}}" class="netlogo-inspector-editor"
                               style="margin: 10px 0" />
      """

  }

})
