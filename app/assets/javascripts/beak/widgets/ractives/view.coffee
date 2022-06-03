import RactiveWidget from "./widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import RactiveEditFormFontSize from "./subcomponent/font-size.js"
import { RactiveEditFormLabeledInput } from "./subcomponent/labeled-input.js"

RactiveEditFormCoordBoundInput = Ractive.extend({

  data: -> {
    id:    undefined # String
  , hint:  undefined # String
  , label: undefined # String
  , max:   undefined # Number
  , min:   undefined # Number
  , name:  undefined # String
  , value: undefined # Number
  }

  isolated: true

  twoway: false

  components: {
    labeledInput: RactiveEditFormLabeledInput
  }

  template:
    """
    <div>
      <labeledInput id="{{id}}" labelStr="{{label}}"
                    labelStyle="min-width: 100px; white-space: nowrap;"
                    name="{{name}}" style="text-align: right;" type="number"
                    attrs="min='{{min}}' max='{{max}}' step=1 required"
                    value="{{value}}" />
      <div class="widget-edit-hint-text">{{hint}}</div>
    </div>
    """

})

ViewEditForm = EditForm.extend({

  data: -> {
    framerate:       undefined # Number
  , isShowingTicks:  undefined # Boolean
  , maxX:            undefined # Number
  , maxY:            undefined # Number
  , minX:            undefined # Number
  , minY:            undefined # Number
  , patchSize:       undefined # Number
  , tickLabel:       undefined # String
  , turtleLabelSize: undefined # Number
  , wrapsInX:        undefined # Boolean
  , wrapsInY:        undefined # Boolean
  }

  computed: {
    topology: {
      get: ->
        if @get('wrapsInX')
          if @get('wrapsInY')
            "Torus"
          else
            "Horizontal Cylinder"
        else if @get('wrapsInY')
          "Vertical Cylinder"
        else
          "Box"
    }
  }

  twoway: false

  components: {
    coordInput:   RactiveEditFormCoordBoundInput
  , formCheckbox: RactiveEditFormCheckbox
  , formFontSize: RactiveEditFormFontSize
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  genProps: (form) ->
    {
      'dimensions.maxPxcor'          : Number.parseInt(form.maxX.value)
    , 'dimensions.maxPycor'          : Number.parseInt(form.maxY.value)
    , 'dimensions.minPxcor'          : Number.parseInt(form.minX.value)
    , 'dimensions.minPycor'          : Number.parseInt(form.minY.value)
    , 'dimensions.patchSize'         : Number.parseInt(form.patchSize.value)
    , 'dimensions.wrappingAllowedInX': form.wrapsInX.checked
    , 'dimensions.wrappingAllowedInY': form.wrapsInY.checked
    , fontSize                       : Number.parseInt(form.turtleLabelSize.value)
    , frameRate                      : Number.parseInt(form.framerate.value)
    , showTickCounter                : form.isShowingTicks.checked
    , tickCounterLabel               : form.tickLabel.value
    }

  # coffeelint: disable=max_line_length
  partials: {

    title: "Model Settings"

    widgetFields:
      """
      {{>worldSet}}
      <spacer height="10px" />
      {{>viewSet}}
      <spacer height="10px" />
      {{>tickCounterSet}}
      """

    worldSet:
      """
      <fieldset class="widget-edit-fieldset">
        <legend class="widget-edit-legend">World</legend>
        <div class="flex-row">
          {{>coordColumn}}
          <spacer width="8%" />
          {{>wrappingColumn}}
        </div>
      </fieldset>
      """

    coordColumn:
      """
      <div class="flex-column">

        <coordInput id="{{id}}-min-x" label="min-pxcor:" name="minX" value="{{minX}}"
                    min="-50000" max="0" hint="minimum x coordinate for patches" />

        <coordInput id="{{id}}-max-x" label="max-pxcor:" name="maxX" value="{{maxX}}"
                    min="0" max="50000" hint="maximum x coordinate for patches" />

        <coordInput id="{{id}}-min-y" label="min-pycor:" name="minY" value="{{minY}}"
                    min="-50000" max="0" hint="minimum y coordinate for patches" />

        <coordInput id="{{id}}-max-y" label="max-pycor:" name="maxY" value="{{maxY}}"
                    min="0" max="50000" hint="maximum y coordinate for patches" />

      </div>
      """

    wrappingColumn:
      """
      <div class="flex-column">
        <formCheckbox id="{{id}}-wraps-in-x" isChecked="{{ wrapsInX }}"
                      labelText="Wraps horizontally" name="wrapsInX" />
        <spacer height="10px" />
        <formCheckbox id="{{id}}-wraps-in-y" isChecked="{{ wrapsInY }}"
                      labelText="Wraps vertically" name="wrapsInY" />
      </div>
      """

    viewSet:
      """
      <fieldset class="widget-edit-fieldset">
        <legend class="widget-edit-legend">View</legend>
        <div class="flex-row">
          <div class="flex-column" style="flex-grow: 1;">
            <labeledInput id="{{id}}-patch-size" labelStr="Patch size:"
                          name="patchSize" type="number" value="{{patchSize}}"
                          attrs="min=-1 step='any' required" />
            <div class="widget-edit-hint-text">measured in pixels</div>
          </div>
          <spacer width="20px" />
          <div class="flex-column" style="flex-grow: 1;">
            <formFontSize id="{{id}}-turtle-label-size" name="turtleLabelSize" value="{{turtleLabelSize}}"/>
            <div class="widget-edit-hint-text">of labels on agents</div>
          </div>
        </div>

        <spacer height="10px" />

        <labeledInput id="{{id}}-framerate" labelStr="Frame rate:" name="framerate"
                      style="text-align: right;" type="number" value="{{framerate}}"
                      attrs="min=0 step='any' required" />
        <div class="widget-edit-hint-text">Frames per second at normal speed</div>

      </fieldset>
      """

    tickCounterSet:
      """
      <fieldset class="widget-edit-fieldset">
        <legend class="widget-edit-legend">Tick Counter</legend>
        <formCheckbox id="{{id}}-is-showing-ticks" isChecked="{{ isShowingTicks }}"
                      labelText="Show tick counter" name="isShowingTicks" />
        <spacer height="10px" />
        <labeledInput id="{{id}}-tick-label" labelStr="Tick counter label:" name="tickLabel"
                      style="width: 230px;" type="text" value="{{tickLabel}}" />
      </fieldset>
      """

  }
  # coffeelint: enable=max_line_length

})

RactiveView = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit]
  , resizeDirs:         ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']
  , ticks:              undefined # String
  }

  computed: {
    viewDims: ->
      { top, right, bottom, left } = VIEW_INNER_SPACING
      "padding: #{top}px #{right}px #{bottom}px #{left}px;"
  }

  components: {
    editForm: ViewEditForm
  }

  eventTriggers: ->
    {
      fontSize:                        [                      @_weg.redrawView]
    , 'dimensions.maxPxcor':           [    @_weg.resizeView, @_weg.redrawView]
    , 'dimensions.maxPycor':           [    @_weg.resizeView, @_weg.redrawView]
    , 'dimensions.minPxcor':           [    @_weg.resizeView, @_weg.redrawView]
    , 'dimensions.minPycor':           [    @_weg.resizeView, @_weg.redrawView]
    , 'dimensions.patchSize':          [ @_weg.resizePatches, @_weg.redrawView]
    , 'dimensions.wrappingAllowedInX': [@_weg.updateTopology, @_weg.redrawView]
    , 'dimensions.wrappingAllowedInY': [@_weg.updateTopology, @_weg.redrawView]
    }

  # (Object[Number]) => Unit
  handleResize: ({ left: newLeft, right: newRight, top: newTop, bottom: newBottom }) ->

    if newLeft >= 0 and newTop >= 0

      oldLeft   = @get('left'  )
      oldRight  = @get('right' )
      oldTop    = @get('top'   )
      oldBottom = @get('bottom')

      oldCanvasWidth  = oldRight  - oldLeft - VIEW_INNER_SPACING.horizontal
      oldCanvasHeight = oldBottom - oldTop - VIEW_INNER_SPACING.vertical

      newCanvasWidth  = newRight  - newLeft - VIEW_INNER_SPACING.horizontal
      newCanvasHeight = newBottom - newTop - VIEW_INNER_SPACING.vertical

      dWidth  = Math.abs(oldCanvasWidth  - newCanvasWidth )
      dHeight = Math.abs(oldCanvasHeight - newCanvasHeight)

      ratio     = if dWidth > dHeight then newCanvasHeight / oldCanvasHeight else newCanvasWidth / oldCanvasWidth
      patchSize = parseFloat((@get('widget.dimensions.patchSize') * ratio).toFixed(2))

      scaledWidth  = patchSize * (@get('widget.dimensions.maxPxcor') - @get('widget.dimensions.minPxcor') + 1)
      scaledHeight = patchSize * (@get('widget.dimensions.maxPycor') - @get('widget.dimensions.minPycor') + 1)

      dx = scaledWidth  - oldCanvasWidth
      dy = scaledHeight - oldCanvasHeight

      movedLeft = newLeft isnt oldLeft
      movedUp   = newTop  isnt oldTop

      [top , bottom] = if movedUp   then [oldTop  - dy, newBottom] else [newTop , oldBottom + dy]
      [left,  right] = if movedLeft then [oldLeft - dx, newRight ] else [newLeft, oldRight  + dx]

      if left >= 0 and top >= 0

        @set('widget.top'   , Math.round(top   ))
        @set('widget.bottom', Math.round(bottom))
        @set('widget.left'  , Math.round(left  ))
        @set('widget.right' , Math.round(right ))

        @findComponent('editForm').set('patchSize', patchSize)

    return

  # () => Unit
  handleResizeEnd: ->
    @fire('set-patch-size', @findComponent('editForm').get('patchSize'))
    @notifyWidgetMoved()
    return

  minWidth:  10
  minHeight: 10

  # coffeelint: disable=max_line_length
  template:
    """
    {{>editorOverlay}}
    {{>view}}
    <editForm idBasis="view" style="width: 510px;"
              maxX="{{widget.dimensions.maxPxcor}}" maxY="{{widget.dimensions.maxPycor}}"
              minX="{{widget.dimensions.minPxcor}}" minY="{{widget.dimensions.minPycor}}"
              wrapsInX="{{widget.dimensions.wrappingAllowedInX}}" wrapsInY="{{widget.dimensions.wrappingAllowedInY}}"
              patchSize="{{widget.dimensions.patchSize}}" turtleLabelSize="{{widget.fontSize}}"
              framerate="{{widget.frameRate}}"
              isShowingTicks="{{widget.showTickCounter}}" tickLabel="{{widget.tickCounterLabel}}" />
    """

  partials: {

    view:
      """
      <div id="{{id}}" class="netlogo-widget netlogo-view-container {{classes}}" style="{{dims}}{{viewDims}}"></div>
      """

  }
  # coffeelint: enable=max_line_length

})

# The spacing between the outer edge of the "view" widget and the inner drawing area/canvas. The dimensions match the
# size of the "border" around the drawing area in the desktop NetLogo app. - David D. 8/2021
VIEW_INNER_SPACING = { top: 5, right: 4, bottom: 4, left: 4 }
VIEW_INNER_SPACING.horizontal = VIEW_INNER_SPACING.left + VIEW_INNER_SPACING.right
VIEW_INNER_SPACING.vertical = VIEW_INNER_SPACING.top + VIEW_INNER_SPACING.bottom

RactiveHNWView = RactiveView.extend({
  data: -> {
    contextMenuOptions: []
  , isNotEditable:      true
  }
})

export { RactiveView, RactiveHNWView, VIEW_INNER_SPACING }
