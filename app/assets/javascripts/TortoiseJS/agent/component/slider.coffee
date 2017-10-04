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
    direction: undefined # String
  , maxCode:   undefined # String
  , minCode:   undefined # String
  , stepCode:  undefined # String
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

  validate: (form) ->
    value = form.value.valueAsNumber
    {
      triggers: {
            max:  [WidgetEventGenerators.recompile]
      ,     min:  [WidgetEventGenerators.recompile]
      ,    step:  [WidgetEventGenerators.recompile]
      , variable: [WidgetEventGenerators.recompile, WidgetEventGenerators.rename]
      }
    , values: {
        currentValue: value
      ,      default: value
      ,    direction: (if form.vertical.checked then "vertical" else "horizontal")
      ,      display: form.variable.value
      ,          max: @findComponent('formMaxCode' ).findComponent('codeContainer').get('code')
      ,          min: @findComponent('formMinCode' ).findComponent('codeContainer').get('code')
      ,         step: @findComponent('formStepCode').findComponent('codeContainer').get('code')
      ,        units: form.units.value
      ,     variable: form.variable.value.toLowerCase()
      }
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
        <labeledInput id="{{id}}-value" labelStr="Value:" name="value" required type="number" value="{{value}}"
                      style="flex-grow: 1; text-align: right;" />
        <labeledInput id="{{id}}-units" labelStr="Units:" labelStyle="margin-left: 10px;" name="units" type="text" value="{{units}}"
                      style="flex-grow: 1; padding: 4px;" />
      </div>

      <spacer height="15px" />

      <formCheckbox id="{{id}}-vertical" isChecked="{{ direction === 'vertical' }}" labelText="Vertical? (not yet supported)"
                    name="vertical" disabled="true" />
      """

  }

})

window.RactiveSlider = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , errorClass: undefined # String
  }

  components: {
    editForm: SliderEditForm
  }

  template:
    """
    {{>slider}}
    <editForm direction="{{widget.direction}}" idBasis="{{id}}" maxCode="{{widget.max}}"
              minCode="{{widget.min}}" stepCode="{{widget.step}}" units="{{widget.units}}"
              value="{{widget.currentValue}}" variable="{{widget.variable}}" />
    """

  partials: {

    slider:
      """
      <label id="{{id}}"
             on-contextmenu="@this.fire('showContextMenu', @event)"
             class="netlogo-widget netlogo-slider netlogo-input {{errorClass}}"
             style="{{dims}}">
        <input type="range"
               max="{{widget.maxValue}}" min="{{widget.minValue}}"
               step="{{widget.stepValue}}" value="{{widget.currentValue}}" />
        <div class="netlogo-slider-label">
          <span class="netlogo-label" on-click="showErrors">{{widget.display}}</span>
          <span class="netlogo-slider-value">
            <input type="number"
                   style="width: {{widget.currentValue.toString().length + 3.0}}ch"
                   min={{widget.minValue}} max={{widget.maxValue}}
                   value={{widget.currentValue}} step={{widget.stepValue}} />
            {{#widget.units}}{{widget.units}}{{/}}
          </span>
        </div>
      </label>
      """

  }

})
# coffeelint: enable=max_line_length
