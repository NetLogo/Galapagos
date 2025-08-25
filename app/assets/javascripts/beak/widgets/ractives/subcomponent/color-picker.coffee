import RactiveModal from './modal.js'
import RactiveAsyncLoader from './async-loader.js'
import {
  hexStringToNetlogoColor,
  rgbaArrayToHex,
  netlogoColorToRGB,
} from "/colors.js"
import CodeUtils from "../../code-utils.js"

COLOR_PICKER_URL = "../assets/pages/color-picker/index.html"
COLOR_PICKER_INLINED_URL = "../assets/pages/color-picker/inlined/index.html"
COLOR_PICKER_INLINED_DATA_NAME = "colorPickerIframe"
RactiveColorPicker = Ractive.extend({
  data: {
    id: "color-picker-modal"  # String
    , url: COLOR_PICKER_URL   # String

    , initialColor: undefined
    , pickerType: "num"          # "num" or "numAndRGBA"
    , defaultPicker: "simple"    # "simple" or "advanced"

    , iframeLoaded: false  # Boolean
  },

  components: {
      modal: RactiveModal
    , asyncLoader: RactiveAsyncLoader
  },

  messageChannel: undefined,  # MessageChannel
  innerBabyMonitor: undefined, # Port1 of MessageChannel

  on: {
    'init': ->
      @messageChannel = new MessageChannel
      @innerBabyMonitor = @messageChannel.port1
      @innerBabyMonitor.onmessage = @onColorPickerEvent.bind(this)

      if ['num', 'numAndRGBA'].indexOf(@get('pickerType')) is -1
        console.warn("RactiveColorPicker: Unknown pickerType '#{@get('pickerType')}', defaulting to 'num'")
        @set('pickerType', 'num')

      htmlString = CodeUtils.dataTagStore.retrieve(COLOR_PICKER_INLINED_DATA_NAME)
      if htmlString
        @set('srcDoc', htmlString)

    'iframe-loaded': (event) ->
        iframe = event.node

        iframe.contentWindow.postMessage({
          type: "init-baby-monitor",
          initialColor: @get('initialColor'),
          pickerType: @get('pickerType'),
          defaultPicker: @get('defaultPicker')
        }, "*", [
          @messageChannel.port2
        ])

        @set('iframeLoaded', true)

        return
  },

  computed: {
    modalId: ->
      "#{@get('id')}-parent"
  },

  onColorPickerEvent: (event) ->
    if event.data.type is 'pick'
      data = { ...event.data, ...@parseColor(event.data.color) }
      @fire('pick', data)
    else if event.data.type is 'cancel'
      @fire('cancel')
    else
      console.warn("RactiveColorPicker: Unknown event type received from color picker:", event.data.type)
      return
    return

  parseColor: (str) ->
    if str.startsWith('[') and str.endsWith(']')
      parts = str.slice(1, -1).split(' ').map((s) ->
        s.trim()
      )
      nums = parts.map((p) ->
        parseFloat(p)
      )

      if nums.length is 4 or nums.length is 3
        rgb = nums.slice(0, 3)
        alpha = if nums.length is 4 then nums[3] else 255
        hex =
          try rgbaArrayToHex(rgb)
          catch ex
            "#000000"
        num =
          try hexStringToNetlogoColor(hex)
          catch ex
            0
        return {
          rgb: nums.slice(0, 3)
          num: num
          alpha: alpha
        }

    else if not isNaN(parseFloat(str))
      num =
        try parseFloat(str)
        catch ex
          0
      rgb =
        try netlogoColorToRGB(num)
        catch ex
          [0, 0, 0]
      return {
        num: parseFloat(str)
        rgb: rgb
        alpha: 255
      }

    throw new Error("Invalid color format")

  template: """
  <modal id="{{modalId}}" title="Color Picker">
    <asyncLoader loading="{{!iframeLoaded}}">
        <iframe id="{{id}}" style="width: 100%; height: 100%;"
                {{#if !srcDoc}} src="{{url}}" {{/if}}
                {{#if srcDoc}} srcDoc="{{srcDoc}}" {{/if}}
                frameborder="0" on-load="iframe-loaded">
        </iframe>
    </asyncLoader>
  </modal>
  """
})

prepareColorPickerForInline = () ->
  try
    response = await fetch(COLOR_PICKER_INLINED_URL)
    htmlString = await response.text()
    CodeUtils.dataTagStore.upsert(COLOR_PICKER_INLINED_DATA_NAME, htmlString)
  catch e
    throw new Error("Failed to prepare RactiveColorPicker for inlining: #{e}")


export default RactiveColorPicker
export {
  prepareColorPickerForInline
}
