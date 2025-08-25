import RactiveColorPicker from "./color-picker.js"
import {
  netlogoColorToHexString
} from "/colors.js"

# This exists to address some trickiness.  Here are the relevant constraints:
#
#   1. HTML color pickers have higher color space resolution than the NetLogo color system
#   2. The color picker must be automatically updated when a color value updates in the engine
#   3. The engine must be automatically updated when a new color is chosen
#
# The logical solution for (2) and (3) is to do the normal two-way binding that we do for the all other
# NetLogo variables.  However, if we do that, the new color will be continually clobbered by the one from
# the engine, since the picker won't get updated until the color picker is closed (and you'll never close it,
# except out of frustration from the fact that your color choice is getting clobbered).  So, okay, we use
# `on-input` instead of `on-change` to update the color before closing the picker.  But then (1) comes into
# play.
#
# So you have this enormous space for visually choosing colors--tens of thousands of points.  However,
# only maybe 20 of those points are valid NetLogo colors.  So, with the variables bound together, you
# pick a color in the picker, and then the picker jumps to the nearest NetLogo-expressible color (which can
# be a pretty far jump).  NetLogo just keeps doing this, ad infinitum.  The user experience feels awful.
# So the solution that I've chosen here is to establish kind of a buffer zone, so that we only update the
# picker when a new value comes in from the engine.
#
# --Jason B. (4/11/18)

RactiveColorInput = Ractive.extend({

  data: -> {
    class:      undefined # String
  , id:         undefined # String
  , isEnabled:  true      # Boolean
  , name:       undefined # String
  , style:      undefined # String
  , value:      undefined # String

  , isModalOpen: false    # Boolean
  }

  components: {
    colorPicker: RactiveColorPicker
  }

  on: {
    click: (event) ->
      if @get('isEnabled')
        @set('isModalOpen', true)

      return false

    "color-picked": (data) ->
      @set('value', data.num)
      @fire('change')

      @set('isModalOpen', false)
      return

    "color-picker-cancel": (event) ->
      @set('isModalOpen', false)
      return false
  }

  computed: {
    initialColor: ->
      value = @get('value') or 0
      return {
        typ: "number",
        value
      }

    hexColor: ->
      netlogoColor = @get('value')
      if typeof netlogoColor is 'number'
        netlogoColorToHexString(netlogoColor)
      else
        "#000000"

    classNames: ->
      [
        'netlogo-color-input',
        if @get('isEnabled') then 'enabled' else 'disabled',
        @get('class')
      ].filter((x) -> x).join(' ')
  }

  template:
    """
    <input id="{{id}}" class="{{class}}" name="{{name}}" style="{{style}}" type="color"
           {{# !isEnabled }}disabled{{/}} value="{{hexColor}}" twoway="false"
           on-click="['click']" />
    {{#isModalOpen}}
    <colorPicker id="{{id}}-color-picker"
                 on-pick="['color-picked']"
                 on-cancel="['color-picker-cancel']"
                 pickerType="num"
                 initialColor="{{initialColor}}" />
    {{/}}
    """

})

export default RactiveColorInput
