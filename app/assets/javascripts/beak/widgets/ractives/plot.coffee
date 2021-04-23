PenForm = Ractive.extend({

  data: -> {
    color:              undefined # Number
  , display:            undefined # String
  , index:              undefined # Number
  , interval:           undefined # Number
  , isExpanded:         false
  , modeIndex:          undefined # Number
  , setupCode:          undefined # String
  , shouldShowInLegend: undefined # Boolean
  , updateCode:         undefined # String
  }

  components: {
    colorInput:   RactiveColorInput
  , formCheckbox: RactiveEditFormCheckbox
  , formCode:     RactiveEditFormMultilineCode
  , formDropdown: RactiveEditFormDropdown
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  computed: {

    id: -> "#{@parent.get('id')}-pen-#{@get('index')}"

    mode: {
      get: -> ['Line', 'Bar', 'Point'][@get('modeIndex')]
      set: (x) -> @set('modeIndex', ['Line', 'Bar', 'Point'].indexOf(x))
    }

    # You'd think that we would already have a NetLogo color here.  You would be wrong.
    # Instead, we have a Java AWT bitmasked color, which needs to be split into its
    # RGB components, and then converted into a NetLogo color. --JAB (4/7/21)
    nlColor: {

      get: ->

        componentToHex = (comp) -> Number(comp).toString(16).padStart(2, '0')
        f              = componentToHex

        c = @get('color')

        r = (c & 0xFF0000) >> 16
        g = (c & 0x00FF00) >>  8
        b = (c & 0x0000FF)

        hexStringToNetlogoColor("##{f(r)}#{f(g)}#{f(b)}")

      set: (nlc) ->
        [r, g, b] = netlogoColorToRGB(nlc)
        @set('color', (-1 << 24) + (r << 16) + (g << 8) + b)
        return

    }

  }

  on: {

    '*.code-changed': ({ component }, newValue) ->
      cid = component.get('id')
      if cid.endsWith('setup-code')
        @set('setupCode', newValue)
      else if cid.endsWith('update-code')
        @set('updateCode', newValue)
      else
        console.warn('Unknown plot pen code container!', component)
      false

    'remove-pen': ->
      @parent.fire('remove-child-pen', @get('index'))
      false

  }

  # coffeelint: disable=max_line_length
  template:
    """
    <div class="flex-column plot-pen-row{{#isExpanded}} open{{/}}">
      <div class="flex-row">
        <label for="{{id}}-is-expanded" class="plot-pen-expander widget-edit-checkbox-wrapper">
          <input id="{{id}}-is-expanded" class="widget-edit-checkbox" style="display: none;" type="checkbox" checked="{{isExpanded}}" />
          <span class="widget-edit-input-label plot-pen-expander-label">&gt;</span>
        </label>
        <colorInput id="{{id}}-color" name="color" value="{{nlColor}}" style="min-height: 33px; min-width: 33px;" />
        <input id="{{id}}-name" name="name" class="widget-edit-text widget-edit-input widget-edit-inputbox"
               style="border-radius: 4px; margin: auto 10px;" type="text" value="{{display}}" />
        <input class="plot-pen-delete" type="button" on-click="remove-pen" value="Delete" />
      </div>
      {{# isExpanded }}
        <spacer height="10px" />
        <div class="flex-row" style="justify-content: space-between;">
          <select id="{{id}}-mode" name="mode" class="widget-edit-dropdown" style="margin-left: 0; width: 80px;" value="{{mode}}">
            <option value="Line" >Line </option>
            <option value="Bar"  >Bar  </option>
            <option value="Point">Point</option>
          </select>
          <div>
            <label for="{{id}}-interval" class="widget-edit-input-label" style="margin-right: 5px;">Interval:</label>
            <input id="{{id}}-interval" name="interval" class="widget-edit-text widget-edit-input widget-edit-inputbox"
                   style="margin: 0 10px 0 0; width: 70px;" min="0" max="10000" type="number" value="{{interval}}">
          </div>
          <formCheckbox id="{{id}}-in-legend?" isChecked={{shouldShowInLegend}} labelText="In legend?" name="legend" />
        </div>
        <spacer height="10px" />
        <formCode id="{{id}}-setup-code"  name="setupCode"  value="{{setupCode}}"  label="Pen setup commands"   style="height: 62px; width: 100%;" />
        <spacer height="10px" />
        <formCode id="{{id}}-update-code" name="updateCode" value="{{updateCode}}" label="Pen update commands"  style="height: 62px; width: 100%;" />
        <spacer height="10px" />
      {{/}}
    </div>
    """
  # coffeelint: enable=max_line_length

})

PlotEditForm = EditForm.extend({

  data: -> {
    autoPlotOn: undefined # Boolean
  , display:    undefined # String
  , legendOn:   undefined # Boolean
  , pens:       undefined # Array[Pen]
  , setupCode:  undefined # String
  , updateCode: undefined # String
  , xLabel:     undefined # String
  , xMax:       undefined # Number
  , xMin:       undefined # Number
  , yLabel:     undefined # String
  , yMax:       undefined # Number
  , yMin:       undefined # Number
  }

  components: {
    formCheckbox: RactiveEditFormCheckbox
  , formCode:     RactiveEditFormMultilineCode
  , formPen:      PenForm
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  twoway: false

  genProps: (form) ->

    getCode =
      (ractive) -> (elemID) ->
        ractive.findAllComponents('formCode').
          find((x) => x.find(elemID)?).
          findComponent('codeContainer').
          get('code')

    {  autoPlotOn: form.autoPlotOn.checked
    ,     display: form.name[0].value
    ,    legendOn: form.legendOn.checked
    ,        pens: @get('pens')
    ,   setupCode: getCode(this)("##{@get('id')}-setup-code")
    ,  updateCode: getCode(this)("##{@get('id')}-update-code")
    ,       xAxis: form.xLabel.value
    ,        xmax: form.xMax.valueAsNumber
    ,        xmin: form.xMin.valueAsNumber
    ,       yAxis: form.yLabel.value
    ,        ymax: form.yMax.valueAsNumber
    ,        ymin: form.yMin.valueAsNumber
    }

  on: {

    'add-new': ->

      freshPen = { color: 0, display: '', inLegend: true, interval: 1, mode: 0, setupCode: '', type: "pen", updateCode: '' }
      @get('pens').push(freshPen)

      @update('pens')

      pens = @findAllComponents('formPen')
      pens[pens.length - 1].set('isExpanded', true)

      false

    init: ->
      if not @get('pens')?
        @set('pens', [])

    'remove-child-pen': (_, index) ->
      @splice('pens', index, 1)
      false

  }

  partials: {

    title: "Plot"

    # coffeelint: disable=max_line_length
    widgetFields:
      """
      <spacer height="15px" />
      <div class="flex-column plot-editor" style="align-items: center;">
        <labeledInput id="{{id}}-name" labelStr="Name:" name="name" class="widget-edit-inputbox" type="text" value="{{display}}" />
        <spacer height="10px" />
        <div class="flex-row" style="justify-content: space-evenly;">
          <div class="flex-column">
            <div class="flex-row">
              <label for="{{id}}-x-label" class="widget-edit-input-label" style="margin-right: 0px; min-width: 70px;">X label:</label>
              <input id="{{id}}-x-label" name="xLabel" class="widget-edit-text widget-edit-input widget-edit-inputbox" type="text" value="{{xLabel}}">
            </div>
            <spacer height="5px" />
            <div class="flex-row">
              <label for="{{id}}-x-min" class="widget-edit-input-label" style="margin-right: 0px; min-width: 70px;">X min:</label>
              <input id="{{id}}-x-min" name="xMin" class="widget-edit-text widget-edit-input widget-edit-inputbox" type="number" value="{{xMin}}">
            </div>
            <spacer height="5px" />
            <div class="flex-row">
              <label for="{{id}}-x-max" class="widget-edit-input-label" style="margin-right: 0px; min-width: 70px;">X max:</label>
              <input id="{{id}}-x-max" name="xMax" class="widget-edit-text widget-edit-input widget-edit-inputbox" type="number" value="{{xMax}}">
            </div>
          </div>
          <spacer width="20px" />
          <div class="flex-column">
            <div class="flex-row">
              <label for="{{id}}-y-label" class="widget-edit-input-label" style="margin-right: 0px; min-width: 70px;">Y label:</label>
              <input id="{{id}}-y-label" name="yLabel" class="widget-edit-text widget-edit-input widget-edit-inputbox" type="text" value="{{yLabel}}">
            </div>
            <spacer height="5px" />
            <div class="flex-row">
              <label for="{{id}}-y-min" class="widget-edit-input-label" style="margin-right: 0px; min-width: 70px;">Y min:</label>
              <input id="{{id}}-y-min" name="yMin" class="widget-edit-text widget-edit-input widget-edit-inputbox" type="number" value="{{yMin}}">
            </div>
            <spacer height="5px" />
            <div class="flex-row">
              <label for="{{id}}-y-max" class="widget-edit-input-label" style="margin-right: 0px; min-width: 70px;">Y max:</label>
              <input id="{{id}}-y-max" name="yMax" class="widget-edit-text widget-edit-input widget-edit-inputbox" type="number" value="{{yMax}}">
            </div>
          </div>
        </div>
        <spacer height="10px" />
        <div class="flex-row" style="justify-content: space-evenly; width: 100%;">
          <formCheckbox id="{{id}}-auto-scale"  isChecked={{autoPlotOn}} labelText="Auto scale?"     name="autoPlotOn" />
          <formCheckbox id="{{id}}-show-legend" isChecked={{legendOn}}   labelText="Display legend?" name="legendOn"   />
        </div>
        <spacer height="10px" />
        <div class="flex-column" style="justify-content: left; width: 100%;">
          <formCode id="{{id}}-setup-code" value="{{setupCode}}" label="Plot setup commands" style="height: 62px; width: 100%;" />
        </div>
        <spacer height="10px" />
        <div class="flex-column" style="justify-content: left; width: 100%;">
          <formCode id="{{id}}-update-code" value="{{updateCode}}" label="Plot update commands" style="height: 62px; width: 100%;" />
        </div>
        <spacer height="10px" />
        <div class="flex-column" style="justify-content: left; margin-left: 18px; width: 100%;">Plot pens</div>
        <div style="border: 2px solid black; height: 300px; overflow-y: scroll; width: 95%;">
          {{#each pens: index}}
            <formPen color="{{color}}" display="{{display}}" index="{{index}}"
                     interval="{{interval}}" modeIndex="{{mode}}" setupCode="{{setupCode}}"
                     shouldShowInLegend="{{inLegend}}" updateCode="{{updateCode}}" />
          {{/each}}
          <input type="button" on-click="@this.fire('add-new')" style="height: 26px; margin: 8px 0 3px 6px;" value="Add Pen" />
        </div>
      </div>
      <spacer height="10px" />
      """
    # coffeelint: enable=max_line_length

  }

})

HNWPlotEditForm = PlotEditForm

window.RactivePlot = RactiveWidget.extend({

  data: -> {
    menuIsOpen:     false
  , resizeCallback: ((x, y) ->)
  }

  components: {
    editForm: PlotEditForm
  }

  eventTriggers: ->
    { autoPlotOn: [@_weg.recompile, @_weg.refreshPlot]
    ,    display: [@_weg.recompile, @_weg.refreshPlot, @_weg.renamePlot]
    ,   legendOn: [@_weg.recompile, @_weg.refreshPlot]
    ,       pens: [@_weg.recompile, @_weg.refreshPlot]
    ,  setupCode: [@_weg.recompile, @_weg.refreshPlot]
    , updateCode: [@_weg.recompile, @_weg.refreshPlot]
    ,      xAxis: [@_weg.recompile, @_weg.refreshPlot]
    ,       xmax: [@_weg.recompile, @_weg.refreshPlot]
    ,       xmin: [@_weg.recompile, @_weg.refreshPlot]
    ,      yAxis: [@_weg.recompile, @_weg.refreshPlot]
    ,       ymax: [@_weg.recompile, @_weg.refreshPlot]
    ,       ymin: [@_weg.recompile, @_weg.refreshPlot]
    }

  observe: {
    'left right top bottom': ->
      @get('resizeCallback')(@get('right') - @get('left'), @get('bottom') - @get('top'))
      return
  }

  on: {

    render: ->

      ractive          = this
      topLevel         = document.querySelector("##{@get('id')}")
      topLevelObserver = new MutationObserver(
        (mutations) -> mutations.forEach(
          ({ addedNodes }) ->
            container = Array.from(addedNodes).find((elem) -> elem.classList.contains("highcharts-container"))
            if container?
              topLevelObserver.disconnect()
              containerObserver = new MutationObserver(
                (mutties) -> mutties.forEach(
                  ({ addedNodes: addedNodies }) ->
                    menu = Array.from(addedNodies).find((elem) -> elem.classList.contains("highcharts-contextmenu"))
                    if menu?
                      ractive.set('menuIsOpen', true)
                      containerObserver.disconnect()
                      menuObserver = new MutationObserver(-> ractive.set('menuIsOpen', menu.style.display isnt "none"))
                      menuObserver.observe(menu, { attributes: true })
                )
              )
              containerObserver.observe(container, { childList: true })
        )
      )
      topLevelObserver.observe(topLevel, { childList: true })

  }

  minWidth:  100
  minHeight: 85

  # coffeelint: disable=max_line_length
  template:
    """
    {{>editorOverlay}}
    <div id="{{id}}" class="netlogo-widget netlogo-plot {{classes}}"
         style="{{dims}}{{#menuIsOpen}}z-index: 10;{{/}}"></div>
    <editForm autoPlotOn={{widget.autoPlotOn}} display="{{widget.display}}" idBasis="{{id}}"
              legendOn={{widget.legendOn}} pens="{{widget.pens}}"
              setupCode="{{widget.setupCode}}" updateCode="{{widget.updateCode}}"
              xLabel="{{widget.xAxis}}" xMin="{{widget.xmin}}" xMax="{{widget.xmax}}"
              yLabel="{{widget.yAxis}}" yMin="{{widget.ymin}}" yMax="{{widget.ymax}}" />
    """
  # coffeelint: enable=max_line_length

})

window.RactiveHNWPlot = RactivePlot.extend({
  components: {
    editForm: HNWPlotEditForm
  }
})
