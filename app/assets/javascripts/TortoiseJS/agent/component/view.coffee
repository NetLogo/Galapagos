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

  isolated: true

  twoway: false

  components: {
    coordInput:   RactiveEditFormCoordBoundInput
  , formCheckbox: RactiveEditFormCheckbox
  , formFontSize: RactiveEditFormFontSize
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  validate: (form) ->
    weg = WidgetEventGenerators
    {
      triggers: {
                  fontSize: [                    weg.redrawView]
      ,           maxPxcor: [    weg.resizeView, weg.redrawView]
      ,           maxPycor: [    weg.resizeView, weg.redrawView]
      ,           minPxcor: [    weg.resizeView, weg.redrawView]
      ,           minPycor: [    weg.resizeView, weg.redrawView]
      ,          patchSize: [                    weg.redrawView]
      , wrappingAllowedInX: [weg.updateTopology, weg.redrawView]
      , wrappingAllowedInY: [weg.updateTopology, weg.redrawView]
      }
    , proxies: {
                  fontSize: form.turtleLabelSize.valueAsNumber
      ,           maxPxcor: form.maxX.valueAsNumber
      ,           maxPycor: form.maxY.valueAsNumber
      ,           minPxcor: form.minX.valueAsNumber
      ,           minPycor: form.minY.valueAsNumber
      ,          patchSize: form.patchSize.valueAsNumber
      , wrappingAllowedInX: form.wrapsInX.checked
      , wrappingAllowedInY: form.wrapsInY.checked
      }
    , values: {
               frameRate: form.framerate.valueAsNumber
      ,  showTickCounter: form.isShowingTicks.checked
      , tickCounterLabel: form.tickLabel.value
      }
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
      <div class="flex-column" style="width: 46%;">

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
      <div class="flex-column" style="width: 46%;">
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
                          attrs="min=-1 required" />
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
                      attrs="min=0 step=1 required" />
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

    agentsUnderMouse:   undefined # Array[Agent]
  , ticks:             undefined # String

  , getAgentMenuText: (agent) ->
      if agent?
        cleansed = agent.toString().replace(/[)(]/g, '')
        "#{cleansed.charAt(0).toUpperCase()}#{cleansed.slice(1)}"

  }

  components: {
    editForm: ViewEditForm
  }


  isolated: true

  oninit: ->
    @_super()

    @on('showContextMenu'
    , ({ original: trueEvent }, menuItemsID) ->

        trueEvent.preventDefault()

        contextMenu               = @parent.find("#netlogo-widget-context-menu")
        contextMenu.style.display = "block"

        for child in contextMenu.children
          child.style.display = "none"

        @find("##{menuItemsID}").style.display = ""

        { height: rh, width: rw } = contextMenu.getBoundingClientRect()
        x = Math.min(trueEvent.pageX, (width  - (rw + 5)))
        y = Math.min(trueEvent.pageY, (height - (rh + 5)))
        contextMenu.style.top    = "#{y}px"
        contextMenu.style.left   = "#{x}px"
        contextMenu.style.zIndex = Math.floor(100 + window.performance.now())

        canvas = @find('.netlogo-view-container').querySelector('canvas')
        { left:     cLeft, height: cHeight, top:      cTop, width: cWidth } = canvas.getBoundingClientRect()
        { minPxcor: tLeft, height: tHeight, maxPycor: tTop, width: tWidth } = world.topology

        x = event.clientX - cLeft
        y = event.clientY - cTop

        xShrinkingFactor = cWidth  / tWidth
        yShrinkingFactor = cHeight / tHeight

        pxcor =   (x / xShrinkingFactor) + (tLeft - 0.5)
        pycor =   (tTop + 0.5) - (y / yShrinkingFactor)

        patch = world.getPatchAt(pxcor, pycor)

        turtles = patch.inRadius(world.turtles(), 2).toArray().filter((t) -> not t.getVariable('hidden?'))
        patches = [patch]

        links =
          world.links().filter(
            (l) ->
              { end1: { xcor: x1, ycor: y1 }, end2: { xcor: x2, ycor: y2 } } = l
              tolerance = l.getVariable('thickness') + 0.5
              (not l.getVariable('hidden?')) and (world.topology.distanceToLine(x1, y1, x2, y2, pxcor, pycor) < tolerance)
          ).toArray()

        @set('agentsUnderMouse', [].concat(turtles, patches, links))

        false

    )

    @on('inspect'
    , (e, agent) ->
        InspectPrims.inspect(agent)
    )

  template:
    """
    {{>view}}
    {{>contextMenu}}
    {{>editForm}}
    """

  partials: {

    view:
      """
      <div id="{{id}}"
           on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
           class="netlogo-widget netlogo-view-container"
           style="{{dims}}">
        <div class="netlogo-widget netlogo-tick-counter">
          {{# widget.showTickCounter }}
            {{widget.tickCounterLabel}}: <span>{{ticks}}</span>
          {{/}}
        </div>
      </div>
      """

    contextMenu:
      """
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          <li class="context-menu-item" on-click="editWidget">Edit</li>
          {{ # agentsUnderMouse }}
            <li class="context-menu-item" on-click="inspect:{{.}}">Inspect {{getAgentMenuText(.)}}</li>
          {{/}}
        </ul>
      </div>
      """

    editForm:
      """
      <editForm idBasis="view"
                maxX="{{widget.maxPxcor}}" maxY="{{widget.maxPycor}}"
                minX="{{widget.minPxcor}}" minY="{{widget.minPycor}}"
                wrapsInX="{{widget.wrappingAllowedInX}}" wrapsInY="{{widget.wrappingAllowedInY}}"
                patchSize="{{widget.patchSize}}" turtleLabelSize="{{widget.fontSize}}"
                framerate="{{widget.frameRate}}"
                isShowingTicks="{{widget.showTickCounter}}" tickLabel="{{widget.tickCounterLabel}}" />
      """

  }

})
