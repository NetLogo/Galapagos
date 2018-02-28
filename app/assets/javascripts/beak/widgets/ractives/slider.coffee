# coffeelint: disable=max_line_length
FlexColumn = Ractive.extend({
  template:
    """
    <div class="flex-column" style="align-items: center; flex-grow: 1; max-width: 140px;">
      {{ yield }}
    </div>
    """
})

SliderEditForm = EditForm.extend({

  data: -> {
    bottom:    undefined # Number
  , direction: undefined # String
  , left:      undefined # Number
  , maxCode:   undefined # String
  , minCode:   undefined # String
  , right:     undefined # Number
  , stepCode:  undefined # String
  , top:       undefined # Number
  , units:     undefined # String
  , value:     undefined # Number
  , variable:  undefined # String
  }

  twoway: false

  components: {
    column:       FlexColumn
  , formCheckbox: RactiveEditFormCheckbox
  , formMaxCode:  RactiveEditFormCodeContainer
  , formMinCode:  RactiveEditFormCodeContainer
  , formStepCode: RactiveEditFormCodeContainer
  , formVariable: RactiveEditFormVariable
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  genProps: (form) ->

    value = form.value.valueAsNumber

    oldTop    = @get('top')
    oldRight  = @get('right')
    oldBottom = @get('bottom')
    oldLeft   = @get('left')

    [right, bottom] =
      if @get('direction') is 'horizontal' and form.vertical.checked
        [oldLeft + (oldBottom - oldTop), oldTop + (oldRight - oldLeft)]
      else if @get('direction') is 'vertical' and not form.vertical.checked
        [oldTop + (oldRight - oldLeft), oldLeft + (oldBottom - oldTop)]
      else
        [oldRight, oldBottom]

    {
            bottom
    , currentValue: value
    ,      default: value
    ,    direction: (if form.vertical.checked then "vertical" else "horizontal")
    ,      display: form.variable.value
    ,          max: @findComponent('formMaxCode' ).findComponent('codeContainer').get('code')
    ,          min: @findComponent('formMinCode' ).findComponent('codeContainer').get('code')
    ,        right
    ,         step: @findComponent('formStepCode').findComponent('codeContainer').get('code')
    ,        units: (if form.units.value isnt "" then form.units.value else undefined)
    ,     variable: form.variable.value.toLowerCase()
    }

  partials: {

    title: "Slider"

    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="variable" value="{{variable}}"/>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: stretch; justify-content: space-around">
        <column>
          <formMinCode id="{{id}}-min-code" label="Minimum" name="minCode" config="{ scrollbarStyle: 'null' }"
                       style="width: 100%;" value="{{minCode}}" />
        </column>
        <column>
          <formStepCode id="{{id}}-step-code" label="Increment" name="stepCode" config="{ scrollbarStyle: 'null' }"
                        style="width: 100%;" value="{{stepCode}}" />
        </column>
        <column>
          <formMaxCode id="{{id}}-max-code" label="Maximum" name="maxCode" config="{ scrollbarStyle: 'null' }"
                       style="width: 100%;" value="{{maxCode}}" />
        </column>
      </div>
      <spacer height="5px" />
      <span style="font-size: 12px;">min, increment, and max may be numbers or reporters</span>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center;">
        <labeledInput id="{{id}}-value" labelStr="Default value:" name="value" type="number" value="{{value}}" attrs="required step='any'"
                      style="flex-grow: 1; text-align: right;" />
        <labeledInput id="{{id}}-units" labelStr="Units:" labelStyle="margin-left: 10px;" name="units" type="text" value="{{units}}"
                      style="flex-grow: 1; padding: 4px;" />
      </div>

      <spacer height="15px" />

      <formCheckbox id="{{id}}-vertical" isChecked="{{ direction === 'vertical' }}" labelText="Vertical?"
                    name="vertical" />
      """

  }

})

window.RactiveSlider = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , errorClass:         undefined # String
  }

  computed: {
    resizeDirs: {
      get: -> if @get('widget.direction') isnt 'vertical' then ['left', 'right'] else ['top', 'bottom']
      set: (->)
    }
  }

  components: {
    editForm: SliderEditForm
  }

  eventTriggers: ->
    {
           max: [@_weg.recompile]
    ,      min: [@_weg.recompile]
    ,     step: [@_weg.recompile]
    , variable: [@_weg.recompile, @_weg.rename]
    }

  template:
    """
    {{>slider}}
    <editForm direction="{{widget.direction}}" idBasis="{{id}}" maxCode="{{widget.max}}"
              minCode="{{widget.min}}" stepCode="{{widget.step}}" units="{{widget.units}}"
              top="{{widget.top}}" right="{{widget.right}}" bottom="{{widget.bottom}}"
              left="{{widget.left}}" value="{{widget.default}}" variable="{{widget.variable}}" />
    {{>editorOverlay}}
    """

  partials: {

    slider:
      """
      <label id="{{id}}" class="netlogo-widget netlogo-slider netlogo-input {{errorClass}}{{#isEditing}} interface-unlocked{{/}}"
             style="{{ #widget.direction !== 'vertical' }}{{dims}}{{else}}{{>verticalDims}}{{/}}">
        <input type="range"
               max="{{widget.maxValue}}" min="{{widget.minValue}}"
               step="{{widget.stepValue}}" value="{{widget.currentValue}}"
               {{# isEditing }}disabled{{/}} />
        <div class="netlogo-slider-label">
          <span class="netlogo-label" on-click="show-errors">{{widget.display}}</span>
          <span class="netlogo-slider-value">
            <input type="number"
                   style="width: {{widget.currentValue.toString().length + 3.0}}ch"
                   min={{widget.minValue}} max={{widget.maxValue}}
                   value={{widget.currentValue}} step={{widget.stepValue}}
                   {{# isEditing }}disabled{{/}} />
            {{#widget.units}}{{widget.units}}{{/}}
          </span>
        </div>
      </label>
      """

    verticalDims:
      """
      position: absolute;
      left: {{ left }}px; top: {{ top }}px;
      width: {{ bottom - top }}px; height: {{ right - left }}px;
      transform: translateY({{ bottom - top }}px) rotate(270deg);
      transform-origin: top left;
      """

  }

})
# coffeelint: enable=max_line_length
