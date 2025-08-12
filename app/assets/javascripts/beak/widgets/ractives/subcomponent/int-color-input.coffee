import {
  argbIntToRGBAArray
, hexStringToRGBArray
, rgbaArrayToARGBInt
, rgbaArrayToHex
} from "/colors.js"

import RactiveColorPicker from './color-picker.js'

# The HTML standard only recently defined a color input that supports setting alpha transparency values.  It is not at
# all well supported as of June 2025.  So yeah.  We also add the ability to disable alpha channel, just to make it easy
# to edit non-transparent values that also use the RGBA integer format.

# https://caniuse.com/mdn-html_elements_input_alpha
# https://html.spec.whatwg.org/multipage/input.html#attr-input-alpha

# -Jeremy B June 2025

RactiveIntColorInput = Ractive.extend({

  data: -> {
    class:     undefined # String
  , id:        undefined # String
  , isEnabled: true      # Boolean
  , useAlpha:  true      # Boolean
  , name:      undefined # String
  , style:     undefined # String
  , value:     undefined # String

  , isModalOpen: false   # Boolean

  , onColorPicked: (data) ->
      if (data.rgb?)
        alpha = 255
        if @get('useAlpha') and typeof data.alpha is 'number'
          alpha = data.alpha
        rgba = [...data.rgb, alpha]
        color = rgbaArrayToARGBInt(rgba)
        @set('value', color)
        @fire('change')
      else if (data.num?)
        throw new Error("Not yet implemented")

      @set('isModalOpen', false)
      return

  , onColorPickerClose: ->
      @set('isModalOpen', false)
      return
  }

  components: {
    colorPicker: RactiveColorPicker
  }

  on: {
    click: (event) ->
      if @get('isEnabled')
        event.original.stopPropagation()
        event.original.preventDefault()

        @set('isModalOpen', true)
      return false
  }

  computed: {
    hexColor: ->
      argbInt = @get('value')
      if typeof argbInt is 'number'
        rgba = argbIntToRGBAArray(argbInt)
        rgbaArrayToHex(rgba.slice(0, 3))
      else
        "#000000"
    
    alpha: ->
      argbInt = @get('value')
      if typeof argbInt is 'number' and @get('useAlpha')
        rgba = argbIntToRGBAArray(argbInt)
        rgba[3]
      else
        255

    classNames: ->
      classes = [
        @get('class'),
        "netlogo-color-input",
        if @get('isEnabled') then undefined else 'netlogo-disabled',
        if @get('useAlpha') then undefined else 'no-alpha'
      ].filter((c) -> c?).join(' ')
  }

  template:
    """
    <div class="{{classNames}}" on-click="['click']">
      <div class="netlogo-swatches">
        <div class="netlogo-swatch" style="background-color: {{hexColor}};"></div>
        {{#useAlpha}}
        <div class="netlogo-swatch" style="background-color: {{hexColor}}; opacity: {{alpha / 255}};"></div>
        {{/}}
      </div>
    </div>
    {{#isModalOpen}}
    <colorPicker id="{{id}}-color-picker"
                 onPick="{{onColorPicked}}"
                 onClose="{{onColorPickerClose}}"
                 pickerType="numAndRGBA"
                 initialColor="{{value}}"
                  />
    {{/}}
    """
})

export default RactiveIntColorInput
