import RactiveModal from './modal.js'
import AsyncLoader from './async-loader.js'
import {
  hexStringToNetlogoColor,
  rgbaArrayToHex,
  netlogoColorToRGB,
} from "/colors.js"

COLOR_PICKER_URL = "/assets/pages/color-picker/index.html"
RactiveColorPicker = Ractive.extend({
  data: {
    id: "color-picker-modal"  # String
    , url: COLOR_PICKER_URL   # String

    , onPick: undefined       # Function
    , onClose: undefined      # Function

    , initialColor: undefined
    , pickerType: "num"          # "num" or "numAndRGBA"
    , defaultPicker: "simple"    # "simple" or "advanced"

    , iframeLoaded: false  # Boolean
  },

  components: {
      modal: RactiveModal
    , asyncLoader: AsyncLoader
  },

  messageChannel: undefined,  # MessageChannel
  innerBabyMonitor: undefined, # Port1 of MessageChannel

  on: {
    init: ->
      @messageChannel = new MessageChannel
      @innerBabyMonitor = @messageChannel.port1
      @innerBabyMonitor.onmessage = @onColorPickerEvent.bind(this)

      if ['num', 'numAndRGBA'].indexOf(@get('pickerType')) is -1
        console.warn("RactiveColorPicker: Unknown pickerType '#{@get('pickerType')}', defaulting to 'num'")
        @set('pickerType', 'num')

    iframeLoaded: (event) ->
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
      @get('onPick')?(data)
    else if event.data.type is 'cancel'
      @get('onClose')?()
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
        parseFloat p
      )

      if nums.length == 4 or nums.length == 3
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

    else if !isNaN(parseFloat(str))
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

    {}


  template: """
  <modal id="{{modalId}}" title="Color Picker">
    <asyncLoader loading="{{!iframeLoaded}}">
        <iframe id="{{id}}" style="width: 100%; height: 100%;"
                src="{{url}}" frameborder="0" on-load="iframeLoaded">
        </iframe>
    </asyncLoader>
  </modal>
  """
})

export default RactiveColorPicker
