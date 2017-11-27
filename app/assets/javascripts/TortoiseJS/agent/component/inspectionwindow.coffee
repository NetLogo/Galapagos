ZoomMax = 100

dialogs = []

window.RactiveInspectionFrame = Ractive.extend({

  startX: undefined # Number
  startY: undefined # Number
  view:   undefined # Element

  data: -> {
    isMinimized: undefined # Boolean
  ,       style: undefined # String
  ,        xLoc: undefined # Number
  ,        yLoc: undefined # Number
  ,      zIndex: undefined # Number
  }

  components: {
    spacer: RactiveEditFormSpacer
  }

  isolated: true

  twoway: false

  oninit: ->

    dialogs.push(this)

    @on('focus'
    , ->
        elem = @find('*')
        elem.focus()
        @set('zIndex', Math.floor(100 + window.performance.now()))
    )

    @on('showYourself'
    , ->

        elem = @find('*')
        @fire('focus')

        # We don't want to reposition if it's already visible --JAB (7/25/16)
        if elem.classList.contains('hidden')

          # Must unhide before measuring and focusing --JAB (3/21/16)
          elem.classList.remove('hidden')
          elem.focus()

          containerMidX = @el.offsetWidth  / 2
          containerMidY = @el.offsetHeight / 2

          dialogHalfWidth  = elem.offsetWidth  / 2
          dialogHalfHeight = elem.offsetHeight / 2

          @set('xLoc', containerMidX - dialogHalfWidth)
          @set('yLoc', containerMidY - dialogHalfHeight)

        false

    )

    @on('activateCloakingDevice'
    , ->
        @find('*').classList.add('hidden')
        false
    )

    @on('startDialogDrag'
    , ({ original: { clientX, clientY, dataTransfer, view } }) ->

        # The drag image looks god-awful, so we create an invisible GIF to replace it. --JAB (8/11/16)
        img     = document.createElement('img')
        img.src = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

        dataTransfer.effectAllowed = "move"
        dataTransfer.setDragImage(img, 0, 0)

        @view   = view
        @startX = @get('xLoc') - clientX
        @startY = @get('yLoc') - clientY

        return

    )

    @on('stopDialogDrag'
    , ->
        @view = undefined
        return
    )

    @on('dragDialog'
    , ({ original: { clientX, clientY, view } }) ->
        # When dragging stops, `client(X|Y)` tend to be very negative nonsense values
        # We only take non-negative values here, to avoid the dialog disappearing --JAB (3/22/16)
        if @view is view and clientX > 0 and clientY > 0
          rect        = this.find('*').getBoundingClientRect()
          bufferSpace = 30
          @set('xLoc', Math.max(0 - (rect.width  - bufferSpace), @startX + clientX))
          @set('yLoc', Math.max(0 - (rect.height - bufferSpace), @startY + clientY))
        false
    )

    @on('closeDialog'
    , ->

        @fire('activateCloakingDevice')

        visibleDialogs = dialogs.filter((d) -> not d.find('*').classList.contains('hidden'))
        if visibleDialogs.length > 0
          getZ = (d) -> parseInt(d.get('zIndex'))
          foremostDialog = visibleDialogs.reduce((best, d) -> if getZ(best) >= getZ(d) then best else d)
          foremostDialog.fire('focus')

        return
    )

    @on('handleKey'
    , ({ original: { keyCode } }) ->
        if keyCode is 27
          @fire('closeDialog')
          false
        return
    )

    @on('toggleMinimized'
    , ->
      @set('isMinimized', !@get('isMinimized'))
      return
    )

    return

  template:
    """
    <div class="netlogo-modal-popup hidden"
         style="top: {{yLoc}}px; left: {{xLoc}}px; {{style}}; {{ # zIndex }} z-index: {{zIndex}} {{/}}"
         on-keydown="handleKey" on-mousedown="focus" tabindex="0">
      <div class="netlogo-dialog-title-strip" draggable="true"
           {{ # isMinimized }}style="border-radius: 5px;"{{/}}
           on-drag="dragDialog" on-dragstart="startDialogDrag"
           on-dragend="stopDialogDrag">
        <div class="netlogo-dialog-title vertically-centered">
          {{>title}}
        </div>
        <div class="netlogo-dialog-nav-options">
          <div class="netlogo-dialog-nav-option" on-click="toggleMinimized">{{ # !isMinimized }}–{{ else }}+{{/}}</div>
          <spacer width="8px" />
          <div class="netlogo-dialog-nav-option" on-click="closeDialog">X</div>
        </div>
      </div>
      <div style="margin: 7px 10px 0 10px; {{ # isMinimized }}display: none;{{/}}">
        {{>innerContent}}
      </div>
    </div>
    """

  partials: {
    innerContent: ""
  }

})

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
    isReadOnly: 'this._getReadOnlyBundle()[${varName}] === true'
    value:      'workspace.dump(${agent}.getVariable(${varName}), true)'
  }

  isolated: true

  twoway: false

  _getReadOnlyBundle: ->
    type = NLType(@get('agent'))
    if type.isTurtle() then TurtleReadOnlies else if type.isLink() then LinkReadOnlies else PatchReadOnlies

  _refreshValue: ->
    value = @get('agent').getVariable(@get('varName'))
    @findComponent('codeInput')?.setInput(workspace.dump(value, true))

  oninit: ->
    @on('codeInput.run-code', (_, code) ->
      @fire('run-code', code)
      @fire('refresh-value')
    )

    @on('refresh-value', ->
      @_refreshValue()
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
  _agent:      undefined # Agent

  # (Canvas, View, Agent) -> MiniView
  constructor: (@_canvas, @_fullView, @_agent) ->

    @_getFocalPoint()

  _getFocalPoint: ->

    [agentX, agentY] = @_agent.getCoords()

    { height: cHeight, width: cWidth, target             } = @_fullView
    { height: tHeight, width: tWidth, minPxcor, maxPycor } = world.topology

    proportionX = ((agentX - (if target then target.xcor else 0)) - (minPxcor - 0.5)) / tWidth
    proportionY = ((maxPycor + 0.5) - (agentY - (if target then target.ycor else 0))) / tHeight

    x = cWidth  * proportionX
    y = cHeight * proportionY

    @_focalPoint = { x, y }

  # Unit -> Unit
  redraw: ->

    @_getFocalPoint()

    { target, wrapX, wrapY }  = @_fullView

    zoomFactor = (ZoomMax - @_scale) / ZoomMax
    maxDim     = Math.max(@_fullView?.width ? 0, @_fullView?.height ? 0)
    length     = maxDim * zoomFactor
    left       = @_focalPoint.x - (length / 2)
    top        = @_focalPoint.y - (length / 2)

    context = @_canvas.getContext("2d")
    context.save()
    context.clearRect(0, 0, @_canvas.width, @_canvas.height)

    xs = if wrapX then [0, @_fullView?.width,  2 * @_fullView?.width ] else [left]
    ys = if wrapY then [0, @_fullView?.height, 2 * @_fullView?.height] else [top]

    tempCanvas        = document.createElement('canvas')
    tempCanvas.width  = @_fullView?.width * 3
    tempCanvas.height = @_fullView?.height * 3

    for dx in xs
      for dy in ys
        tempCanvas.getContext('2d').drawImage(@_fullView, dx, dy)

    context.drawImage(tempCanvas
                    , left + @_fullView?.width, top + @_fullView?.height, length, length
                    , 0, 0, @_canvas.width, @_canvas.height)

    context.restore()

    return

  # Number -> Unit
  rescale: (@_scale) ->
    @redraw()
    return

window.RactiveInspectionWindow = RactiveInspectionFrame.extend({

  data: -> {
    agent: undefined       # Agent
    style: "width: 320px;" # String
    view:  undefined       # Canvas
  }

  computed: {
    agentName: '${agent}.toString()'
    id:        '${agentName}.replace(/[ )(]/g, "")'
  }

  isolated: true

  components: {
    inspectionCommandCenter: RactiveNetLogoCodeInput
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

    initialize = =>
      @find('.inspector-zoom-slider').value = ZoomMax * .8
      @find('.inspector-zoom-slider').dispatchEvent(new CustomEvent('input')) # Trigger `handleZoom` right away
      @findComponent('inspectionCommandCenter').refresh() # CodeMirror is whiny about reflows --JAB (8/22/16)
      return

    @on('watchAgent', -> @get('agent').watchMe(); return)
    @on('handleZoom', ({ original: { target: { value } } }) -> miniView.rescale(parseFloat(value)); return)
    @on('showYourself', initialize)
    @on('redraw', ->
      miniView.redraw()
      for component in @findAllComponents('varRow')
        component._refreshValue()
    )
    initialize()

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
      {{agent.toString().replace(/[)(]/g, '')}}
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
               type="range" min="0" max="#{ZoomMax * .999}" step="#{ZoomMax * .001}" value="#{ZoomMax * .8}" />
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
