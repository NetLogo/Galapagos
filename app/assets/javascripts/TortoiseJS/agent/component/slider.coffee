# coffeelint: disable=max_line_length
LabeledInput = Ractive.extend({

  data: -> {
    id:         undefined # String
  , labelStr:   undefined # String
  , labelStyle: undefined # String
  , name:       undefined # String
  , style:      undefined # String
  , type:       undefined # String
  , value:      undefined # String
  }

  twoway: false

  template:
    """
    <label for="{{id}}" style="{{labelStyle}}">{{labelStr}}</label>
    <input id="{{id}}" name="{{name}}" type="{{type}}" value="{{value}}"
           style="font-size: 20px; height: 26px; margin-left: 10px; {{style}}" />
    """

})

FlexColumn = Ractive.extend({
  template:
    """
    <div style="display: flex; align-items: center; flex-direction: column; flex-grow: 1; max-width: 140px;">
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
  , varName:   undefined # String
  }

  isolated: true

  twoway: false

  components: {
    column:       FlexColumn
  , formCheckbox: RactiveEditFormCheckbox
  , formMaxCode:  RactiveEditFormCodeContainer
  , formMinCode:  RactiveEditFormCodeContainer
  , formStepCode: RactiveEditFormCodeContainer
  , formVariable: RactiveEditFormVariable
  , labeledInput: LabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  validate: (form) ->
    value = form.value.valueAsNumber
    {
      currentValue: value
    ,      default: value
    ,    direction: (if form.vertical.checked then "vertical" else "horizontal")
    ,      display: form.varName.value
    ,          max: @findComponent('formMaxCode' ).findComponent('codeContainer').get('code')
    ,          min: @findComponent('formMinCode' ).findComponent('codeContainer').get('code')
    ,         step: @findComponent('formStepCode').findComponent('codeContainer').get('code')
    ,        units: form.units.value
    ,      varName: form.varName.value.toLowerCase()
    }

  partials: {

    title: "Slider"

    widgetFields:
      """
      <formVariable id="{{id}}-varname" name="varName" value="{{varName}}"/>

      <spacer height="15px" />

      <div style="display: flex; align-items: stretch; flex-direction: row; justify-content: space-around">
        <column>
          <formMinCode id="{{id}}-min-code" label="Minimum" name="minCode" style="width: 100%;" value="{{minCode}}" />
        </column>
        <column>
          <formStepCode id="{{id}}-step-code" label="Increment" name="stepCode" style="width: 100%;" value="{{stepCode}}" />
        </column>
        <column>
          <formMaxCode id="{{id}}-max-code" label="Maximum" name="maxCode" style="width: 100%;" value="{{maxCode}}" />
        </column>
      </div>
      <spacer height="5px" />
      <span style="font-size: 12px;">min, increment, and max may be numbers or reporters</span>

      <spacer height="15px" />

      <div style="display: flex; align-items: center; flex-direction: row;">
        <labeledInput id="{{id}}-value" labelStr="Value:" name="value" required type="number" value="{{value}}"
                      style="flex-grow: 1; text-align: right; width: 100px;" />
        <labeledInput id="{{id}}-units" labelStr="Units:" labelStyle="margin-left: 10px;" name="units" type="text" value="{{units}}"
                      style="flex-grow: 1; padding: 4px; width: 100px;" />
      </div>

      <spacer height="15px" />

      <formCheckbox id="{{id}}-vertical" isChecked="{{ direction === 'vertical' }}" labelText="Vertical?" name="vertical" />
      """

  }

})

window.RactiveSlider = RactiveWidget.extend({

  data: -> {
    errorClass: undefined # String
  }

  components: {
    editForm: SliderEditForm
  }

  isolated: true

  template:
    """
    {{>slider}}
    {{>contextMenu}}
    <editForm direction="{{widget.direction}}" idBasis="{{id}}" maxCode="{{widget.max}}"
              minCode="{{widget.min}}" stepCode="{{widget.step}}" units="{{widget.units}}"
              value="{{widget.currentValue}}" varName="{{widget.varName}}" />
    """

  partials: {

    slider:
      """
      <label id="{{id}}"
             on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
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

    contextMenu:
      """
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          <li class="context-menu-item" on-click="editWidget">Edit</li>
          <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
        </ul>
      </div>
      """

  }

})
# coffeelint: enable=max_line_length
