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
      'dimensions.maxPxcor'          : form.maxX.valueAsNumber
    , 'dimensions.maxPycor'          : form.maxY.valueAsNumber
    , 'dimensions.minPxcor'          : form.minX.valueAsNumber
    , 'dimensions.minPycor'          : form.minY.valueAsNumber
    , 'dimensions.patchSize'         : form.patchSize.valueAsNumber
    , 'dimensions.wrappingAllowedInX': form.wrapsInX.checked
    , 'dimensions.wrappingAllowedInY': form.wrapsInY.checked
    , fontSize                       : form.turtleLabelSize.valueAsNumber
    , frameRate                      : form.framerate.valueAsNumber
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

window.RactiveView = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit]
  , resizeDirs:         ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']
  , ticks:              undefined # String
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
    , 'dimensions.patchSize':          [                      @_weg.redrawView]
    , 'dimensions.wrappingAllowedInX': [@_weg.updateTopology, @_weg.redrawView]
    , 'dimensions.wrappingAllowedInY': [@_weg.updateTopology, @_weg.redrawView]
    }

  on: {

    'widget-resized': (_, oldLeft, oldRight, oldTop, oldBottom, newLeft, newRight, newTop, newBottom) ->

      oldWidth  = oldRight  - oldLeft
      oldHeight = oldBottom - oldTop

      newWidth  = newRight  - newLeft
      newHeight = newBottom - newTop

      dWidth  = Math.abs(oldWidth  - newWidth )
      dHeight = Math.abs(oldHeight - newHeight)

      ratio     = if dWidth > dHeight then newWidth / oldWidth else newHeight / oldHeight
      patchSize = parseFloat((@get('widget.dimensions.patchSize') * ratio).toFixed(2))

      scaledWidth  = patchSize * (@get('widget.dimensions.maxPxcor') - @get('widget.dimensions.minPxcor') + 1)
      scaledHeight = patchSize * (@get('widget.dimensions.maxPycor') - @get('widget.dimensions.minPycor') + 1)

      dx = Math.round((scaledWidth  - oldWidth ) / 2)
      dy = Math.round((scaledHeight - oldHeight) / 2)

      @set('widget.top'   , oldTop    - dy)
      @set('widget.bottom', oldBottom + dy)
      @set('widget.left'  , oldLeft   - dx)
      @set('widget.right' , oldRight  + dx)

      @findComponent('editForm').set('patchSize', patchSize)
      @fire('set-patch-size', patchSize)
      @fire('redraw-view')

  }

  # coffeelint: disable=max_line_length
  template:
    """
    {{>view}}
    <editForm idBasis="view"
              maxX="{{widget.dimensions.maxPxcor}}" maxY="{{widget.dimensions.maxPycor}}"
              minX="{{widget.dimensions.minPxcor}}" minY="{{widget.dimensions.minPycor}}"
              wrapsInX="{{widget.dimensions.wrappingAllowedInX}}" wrapsInY="{{widget.dimensions.wrappingAllowedInY}}"
              patchSize="{{widget.dimensions.patchSize}}" turtleLabelSize="{{widget.fontSize}}"
              framerate="{{widget.frameRate}}"
              isShowingTicks="{{widget.showTickCounter}}" tickLabel="{{widget.tickCounterLabel}}" />
    {{>editorOverlay}}
    """

  partials: {

    view:
      """
      <div id="{{id}}" class="netlogo-widget netlogo-view-container{{#isEditing}} interface-unlocked{{/}}" style="{{dims}}"></div>
      """

  }
  # coffeelint: enable=max_line_length

})
