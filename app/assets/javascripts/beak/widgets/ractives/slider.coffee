import RactiveValueWidget from "./value-widget.js"
import EditForm from "./edit-form.js"
import { RactiveEditFormCheckbox } from "./subcomponent/checkbox.js"
import { RactiveEditFormOneLineCode } from "./subcomponent/code-container.js"
import { RactiveEditFormDropdown } from "./subcomponent/dropdown.js"
import RactiveEditFormVariable from "./subcomponent/variable.js"
import RactiveEditFormSpacer from "./subcomponent/spacer.js"
import { RactiveEditFormLabeledInput } from "./subcomponent/labeled-input.js"
import RactiveCustomSlider from "./subcomponent/custom-slider.js"
import { isMac } from "../accessibility/utils.js"

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
  , height:    undefined # Number
  , maxCode:   undefined # String
  , minCode:   undefined # String
  , stepCode:  undefined # String
  , units:     undefined # String
  , value:     undefined # Number
  , variable:  undefined # String
  , width:     undefined # Number
  , x:         undefined # Number
  , y:         undefined # Number
  , oldSize:   undefined # Boolean
  }

  twoway: false

  components: {
    column:       FlexColumn
  , formCheckbox: RactiveEditFormCheckbox
  , formMaxCode:  RactiveEditFormOneLineCode
  , formMinCode:  RactiveEditFormOneLineCode
  , formStepCode: RactiveEditFormOneLineCode
  , formVariable: RactiveEditFormVariable
  , labeledInput: RactiveEditFormLabeledInput
  , spacer:       RactiveEditFormSpacer
  }

  genProps: (form) ->

    value = Number.parseFloat(form.value.value)

    oldX      = @get('x')
    oldY      = @get('y')
    oldWidth  = @get('width')
    oldHeight = @get('height')

    [width, height] =
      if (@get('direction') is 'horizontal' and     form.vertical.checked) or
         (@get('direction') is 'vertical'   and not form.vertical.checked)
        [oldHeight, oldWidth]
      else
        [oldWidth, oldHeight]

    {
      currentValue: value
    ,      default: value
    ,    direction: (if form.vertical.checked then "vertical" else "horizontal")
    ,      display: form.variable.value
    ,       height
    ,          max: @findComponent('formMaxCode' ).findComponent('codeContainer').get('code')
    ,          min: @findComponent('formMinCode' ).findComponent('codeContainer').get('code')
    ,         step: @findComponent('formStepCode').findComponent('codeContainer').get('code')
    ,        units: (if form.units.value isnt "" then form.units.value else undefined)
    ,     variable: form.variable.value.toLowerCase()
    ,        width
    ,      oldSize: form.oldSize.checked
    }

  partials: {

    title: "Slider"

    variableForm:
      """
      <formVariable id="{{id}}-varname" name="variable" label="Global variable" value="{{variable}}"/>
      """

    widgetFields:
      """
      {{>variableForm}}

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

      <div class="widget-edit-hint-text" style="margin-left: 4px; margin-right: 4px;">min, increment, and max may be numbers or reporters</div>

      <div class="flex-row" style="align-items: center;">
        <labeledInput id="{{id}}-value" labelStr="Default value:" name="value" type="number" value="{{value}}" attrs="required step='any'"
                      style="flex-grow: 1; text-align: right;" />
        <labeledInput id="{{id}}-units" labelStr="Units:" labelStyle="margin-left: 10px;" name="units" type="text" value="{{units}}"
                      style="flex-grow: 1; padding: 4px;" />
      </div>

      <spacer height="15px" />

      <div class="flex-row" style="align-items: center; justify-content: space-between; margin-left: 4px; margin-right: 4px;">
        <formCheckbox id="{{id}}-vertical" isChecked="{{ direction === 'vertical' }}" labelText="Vertical?"
                    name="vertical" />
        <formCheckbox id="{{id}}-old-size" isChecked="{{ oldSize }}" labelText="Use old widget sizing"
                    name="oldSize" name="oldSize" />
      </div>
      """

  }

})

HNWSliderEditForm = SliderEditForm.extend({

  components: {
    formDropdown: RactiveEditFormDropdown
  }

  computed: {
    sortedBreedVars: {
      get: -> @get('breedVars').slice(0).sort()
      set: (x) -> @set('breedVars', x)
    }
  }

  data: -> {
    breedVars: undefined # Array[String]
  }

  on: {
    'use-new-var': (_, varName) ->
      @set('variable', varName)
      return
  }

  partials: {

    variableForm:
      """
      <div class="flex-row">
        <formDropdown id="{{id}}-varname" name="variable" label="Turtle variable"
                      choices="{{sortedBreedVars}}" selected="{{variable}}" />
        <button on-click="@this.fire('add-breed-var', @this)" type="button" style="height: 30px;">Define New Variable</button>
      </div>
      """

  }

})

RactiveSlider = RactiveValueWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).edit, @standardOptions(this).delete]
  , breedVars:          undefined # Array[String]
  , errorClass:         undefined # String
  , internalValue:      0         # Number
  , onValueChange: (val) ->
      @set("internalValue", val)
      @fire("widget-value-change")
  }

  widgetType: "slider"

  sliderElem: null # HTMLElement
  inputElem:  null # HTMLElement

  # () => Unit
  focusSlider: () ->
    if @sliderElem?
      # This is a hack to get the browser to apply
      # :focus-visible instead of :focus to the slider.
      # -Omar I. Aug 11, 2025
      @sliderElem.contentEditable = true
      @sliderElem.focus()
      @sliderElem.contentEditable = false
    return

  on: {
    'render': (context) ->
      @sliderElem = @find("#" + @get('sliderId'))
      @inputElem  = @find("#" + @get('inputId'))

    'reset-if-invalid': (context) ->
      # input elements don't reject out-of-range hand-typed numbers so we have to do the dirty work
      if (context.node.validity.rangeOverflow)
        @set('internalValue', @get('widget.maxValue'))
      else if (context.node.validity.rangeUnderflow)
        @set('internalValue', @get('widget.minValue'))

      @fire('widget-value-change')
      return

    'handle-keydown': (context) ->
      event  = context.original
      key    = event.key
      modKey = if isMac then event.metaKey else event.ctrlKey

      if ['i', 'I'].includes(key) and modKey
        event.preventDefault()
        @fire('switch-input-focus')

    'switch-input-focus': (context) ->
      if document.activeElement is @sliderElem and @inputElem?
        @inputElem.focus()
      else if document.activeElement is @inputElem and @sliderElem?
        @focusSlider()
      return

    'focus-slider': (context) ->
      if context.original.target?.tagName is 'INPUT' \
        and context.original.target?.type is 'number'
        return
      context.original.stopPropagation()
      context.original.preventDefault()
      @focusSlider()
      return

    'update-widget-value-from-string': (_, str) ->
      widget = @get('widget')
      try
        num = parseFloat(str)
        if not isNaN(num)
          @set('internalValue', num)
          @fire('widget-value-change')
        else
          throw new Error("Not a number")
      catch error
        alert("Failed to parse value: " + error)
      return
  }

  computed: {
    textWidth: ->
      internalValue = @get('internalValue')
      if internalValue?
        (internalValue.toString().length) + 3.0
      else
        3

    inputId: -> if @get('id') then "#{@get('id')}-input-field" else null
    sliderId: -> if @get('id') then "#{@get('id')}-custom-slider" else null
  }

  components: {
    editForm: SliderEditForm,
    customSlider: RactiveCustomSlider
  }

  eventTriggers: ->
    {
      currentValue: [@_weg.updateEngineValue]
    ,          max: [@_weg.recompile]
    ,          min: [@_weg.recompile]
    ,         step: [@_weg.recompile]
    ,     variable: [@_weg.recompile, @_weg.rename]
    }

  minWidth:  60
  minHeight: 33

  template:
    """
    {{>editorOverlay}}
    {{>slider}}
    <editForm direction="{{widget.direction}}" idBasis="{{id}}" maxCode="{{widget.max}}"
              minCode="{{widget.min}}" stepCode="{{widget.step}}" units="{{widget.units}}"
              y="{{widget.y}}" width="{{widget.width}}" height="{{widget.height}}"
              x="{{widget.x}}" value="{{widget.default}}" variable="{{widget.variable}}"
              breedVars="{{breedVars}}" oldSize={{widget.oldSize}} />
    """

  partials: {

    className: "netlogo-widget netlogo-slider netlogo-input {{#widget.oldSize}}old-size{{/}} {{errorClass}} {{classes}}"
    style:     "{{ #widget.direction !== 'vertical' }}{{dims}}{{else}}{{>verticalDims}}{{/}}"
    aria:      """
      role="slider"
      aria-valuemin="{{widget.minValue}}"
      aria-valuemax="{{widget.maxValue}}"
      aria-valuenow="{{internalValue}}"
      aria-label="{{widget.display}} slider"
      aria-disabled="{{isEditing}}"
      aria-valuetext="{{internalValue}} {{#widget.units}}{{widget.units}}{{/}}"
      """
    slider:
      """
      <label id="{{id}}" class="{{>className}}" style="{{>style}}" {{>aria}}
             on-click="['focus-slider']" on-keydown="['handle-keydown']"
             on-copy='copy-current-value' on-paste='paste-into-current-value'>
        <div class="netlogo-slider-label">
          <span class="netlogo-label" aria-label="Slider Variable Name"
                on-click="['show-widget-errors', widget]">{{widget.display}}</span>
          <span class="netlogo-slider-value">
            <input
              class="netlogo-slider-value-input"
              id="{{inputId}}"
              type="number"
              on-change="reset-if-invalid"
              style="width: {{textWidth}}ch"
              min="{{widget.minValue}}"
              max="{{widget.maxValue}}"
              step="{{widget.stepValue}}"
              value="{{internalValue}}"
              tabindex="-1"
              aria-label="Slider Value Input Field"
              {{# isEditing }}disabled{{/}} />
            {{#widget.units}}{{widget.units}}{{/}}
          </span>
        </div>
        <customSlider
          id="{{sliderId}}"
          class="{{id}}-custom"
          min="{{widget.minValue}}"
          max="{{widget.maxValue}}"
          step="{{widget.stepValue}}"
          value="{{internalValue}}"
          onChange="{{onValueChange}}"
          orientation="{{widget.direction}}"
          tabindex="{{tabindex}}"/>
      </label>
      """

    verticalDims:
      """
      position: absolute;
      left: {{ x }}px; top: {{ y }}px;
      width: {{ height }}px; height: {{ width }}px;
      transform: translateY({{ height }}px) rotate(270deg);
      transform-origin: top left;
      """

  }

})
# coffeelint: enable=max_line_length

RactiveHNWSlider = RactiveSlider.extend({
  components: {
    editForm: HNWSliderEditForm
  }
})

export { RactiveSlider, RactiveHNWSlider }
