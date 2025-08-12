import RactiveModal from './modal.js'
import AsyncLoader from './async-loader.js'

COLOR_PICKER_URL = "/assets/pages/color-picker/index.html"
RactiveColorPicker = Ractive.extend({
  data: {
    id: "color-picker-modal"  # String
    , url: COLOR_PICKER_URL   # String

    , onPick: undefined       # Function
    , onClose: undefined      # Function

    , initialColor: undefined
    , pickerType: "num"          # "num" or "numAndRGBA"

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
        @set('iframeLoaded', true)
        iframe = event.node

        iframe.contentWindow.postMessage({
          type: "init-baby-monitor",
          initialColor: { typ: "number", value: @get('initialColor') }
          pickerType: @get('pickerType')
        }, "*", [
          @messageChannel.port2
        ])
        return
  },

  computed: {
    modalId: ->
      "#{@get('id')}-parent"
  },

  onColorPickerEvent: (event) ->
    if event.data.type is 'pick'
      @get('onPick')?(event.data)
    else if event.data.type is 'cancel'
      @get('onClose')?()
    else
      console.warn("RactiveColorPicker: Unknown event type received from color picker:", event.data.type)
      return
    return

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
