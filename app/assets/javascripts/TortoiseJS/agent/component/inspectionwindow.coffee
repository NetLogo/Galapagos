ZoomMax = 1000

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
        value = @get('agent').getVariable(@get('varName'))
        @findComponent('codeInput')?.setInput(Dump(value, true))
    )

  oncomplete: ->
    @findComponent('codeInput')?.refresh() # CodeMirror is whiny about reflows sometimes. --JAB (7/22/16)

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

class MiniView

  _scale:      undefined # Number
  _focalPoint: undefined # Point

  # (Canvas, View, Agent) -> MiniView
  constructor: (@_canvas, @_fullView, agent) ->

    [agentX, agentY] = agent.getCoords()

    { height: cHeight, width: cWidth                     } = @_fullView
    { height: tHeight, width: tWidth, minPxcor, maxPycor } = world.topology

    proportionX = (agentX - (minPxcor - 0.5)) / tWidth
    proportionY = ((maxPycor + 0.5) - agentY) / tHeight

    x = cWidth  * proportionX
    y = cHeight * proportionY

    @_focalPoint   = { x, y }

  # Unit -> Unit
  redraw: ->

    length = ZoomMax - @_scale
    left   = @_focalPoint.x - (length / 2)
    top    = @_focalPoint.y - (length / 2)

    context = @_canvas.getContext("2d")
    context.save()
    context.clearRect(0, 0, @_canvas.width, @_canvas.height)
    context.drawImage(@_fullView
                    , left, top, length, length
                    , 0, 0, @_canvas.width, @_canvas.height)
    context.restore()

    return

  # Number -> Unit
  rescale: (@_scale) ->
    @redraw()
    return

window.RactiveInspectionWindow = RactiveOnTopDialog.extend({

  data: -> {
    agent: undefined       # Agent
    style: "width: 300px;" # String
    view:  undefined       # Canvas
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

  oncomplete: ->
    @_super()

    canvas  = @find("##{@get('id')}-canvas")
    context = canvas.getContext("2d")
    context.imageSmoothingEnabled       = false
    context.webkitImageSmoothingEnabled = false
    context.mozImageSmoothingEnabled    = false
    context.oImageSmoothingEnabled      = false
    context.msImageSmoothingEnabled     = false

    miniView = new MiniView(canvas, @get('view'), @get('agent'))

    @on('watchAgent', -> @get('agent').watchMe(); return)
    @on('handleZoom', ({ original: { target: { value } } }) -> miniView.rescale(parseFloat(value)); return)
    @find('.inspector-zoom-slider').dispatchEvent(new CustomEvent('input')) # Trigger `handleZoom` right away

    return

  partials: {

    innerContent:
      """
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
        <input class="inspector-zoom-slider" style="flex-grow: 1" on-input="handleZoom"
               type="range" min="0" max="#{ZoomMax * .99}" step="#{ZoomMax * .01}" value="#{ZoomMax * .8}" />
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
