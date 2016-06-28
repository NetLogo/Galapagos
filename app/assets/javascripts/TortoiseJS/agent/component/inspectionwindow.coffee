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

VarRow = Ractive.extend({

  data: -> {
    agent:   undefined # Agent
    id:      undefined # String
    varName: undefined # String
  }

  computed: {
    isReadOnly: 'this._getReadOnlyBundle()[${varName}] === true'
    #value:      "Dump(${agent}.getVariable(${varName}), true)"
    value:      '${agent}.getVariable(${varName})'
  }

  isolated: true

  twoway: false

  _getReadOnlyBundle: ->
    type = NLType(@get('agent'))
    if type.isTurtle() then TurtleReadOnlies else if type.isLink() then LinkReadOnlies else PatchReadOnlies

  oninit: ->
    @on('handleKeypress'
    , ({ original: { keyCode, target } }) ->
        if keyCode is 13 # Enter key
          value = target.value
          @get('agent').setVariable(@get('varName'), value)
        return
    )

  template:
    """
    <div class="flex-row" style="align-items: center;">
      <label for="{{id}}-input" class="inspection-window-var-label" title="{{varName}}">{{varName}}</label>
      <div style="flex-grow: 1;">
        <input id="{{id}}-input" class="widget-edit-text widget-edit-input" on-keyup="handleKeypress"
               style="padding-right: 6px; text-align: right;" type="text" value="{{value}}"
               {{# isReadOnly }} disabled {{/}} />
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
    id: '${agent}.toString().replace(/[ )(]/g, "")'
  }

  isolated: true

  components: {
    codeEditor: RactiveEditFormCodeContainer
  , varRow:     VarRow
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
      <codeEditor id="{{id}}-code-input" label="" config="{ extraKeys: { Enter: function(editor) { ('ask {{agent.toString()}} [ ' + editor.getValue() + ' ]'); } }, scrollbarStyle: 'null' }"
                  style="margin: 8px 0; width: 100%;" value="" />
      """

  }

})
