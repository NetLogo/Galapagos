import {
  argbIntToRGBAArray
, hexStringToRGBArray
, rgbaArrayToARGBInt
, rgbaArrayToHex
} from "/colors.js"

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
  }

  setColorValue: (hexColor, alpha) ->
    rgba =
      try hexStringToRGBArray(hexColor)
      catch ex
        [0, 0, 0]

    rgba.push(if @get('useAlpha') then alpha else 255)
    color = rgbaArrayToARGBInt(rgba)

    @set('value', color)
    @fire('change')
    return

  on: {

    'color-changed': ({ node: { value: hexColor } }) ->
      @setColorValue(hexColor, @get('alpha'))
      false

    'alpha-changed': ({ node: { value: alphaString } }) ->
      @setColorValue(@get('hexColor'), parseInt(alphaString))
      false

    render: ->
      argbInt  = @get('value')
      rgba     = argbIntToRGBAArray(argbInt)
      hexColor = rgbaArrayToHex(rgba.slice(0, 3))
      alpha    = rgba[3]

      @set('hexColor', hexColor)
      @set('alpha',    alpha)
      return

  }

  template:
    """
    <div class="netlogo-display-vertical">
      <input
        id="{{id}}" class="{{class}}" name="{{name}}" style="{{style}}" type="color"
        value="{{hexColor}}"
        on-change="color-changed"
        {{# !isEnabled }}disabled{{/}} />
      {{# useAlpha }}
      <div class="netlogo-display-horizontal" style="align-items: center;">
        <div style="font-size: 10px;">opacity</div>
        <input id="{{id}}-alpha" type="range" max="255" min="0" step="1"
          value="{{alpha}}"
          on-change="alpha-changed"
          {{# !isEnabled }}disabled{{/}} />
        </div>
      {{/}}
    </div>
    """

})

export default RactiveIntColorInput
