import RactiveModal from './subcomponent/modal.js'

# (Array[Object]) => String
generateKeybindRows = (keybinds) ->
  rows = keybinds.map((keybind) ->
    combo =  keybind.combo
    description = keybind.metadata?.description or 'No description available'
    formattedCombo = combo.toString()

    """
    <tr>
      <td class="keyboard-help-key">
        <kbd>#{formattedCombo}</kbd>
      </td>
      <td class="keyboard-help-description">#{description}</td>
    </tr>
    """
  ).join('\n')

  return """
    <table class="keyboard-help-table">
      <thead>
        <tr>
          <th>Key Combination</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        #{rows}
      </tbody>
    </table>
  """

RactiveKeyboardHelp = Ractive.extend({

  data: -> {
    id: "keyboard-help-dialog"
    isVisible: false
    isOverlayUp: false
    wareaHeight: 600
    wareaWidth: 600
    keyboardListener: null
  }

  keybindsData: []
  keybindsHtml: ""

  observe: {
    isVisible: (newValue) ->
      @set('isOverlayUp', newValue)
      if newValue
        setTimeout((=> @find('#keyboard-help-dialog')?.focus?()), 0)
        @fire('dialog-opened', this)
      else
        @fire('dialog-closed', this)
      return
  }

  on: {
    'init': ->
      listener = @get('keyboardListener')
      return [] unless listener?

      keybinds = []
      if listener.keybinds?
        listener.keybinds.forEach((value, combo) ->
          keybinds.push({
            combo: combo
            callback: value.callback
            id: value.id
            metadata: value.metadata
          })
        )
      @set('keybindsData', keybinds)
      @set('keybindsHtml', generateKeybindRows(keybinds))
      return

    'close-help': ->
      @set('isVisible', false)
      false

    'handle-key': ({ original: { key } }) ->
      if key is "Escape"
        @fire('close-help')
        false
  }

  show: ->
    @set('isVisible', true)

  hide: ->
    @set('isVisible', false)

  components: {
    modal: RactiveModal
  }

  template:
    """
    {{#if isVisible }}
    <div class="keyboard-help-backdrop" on-click="close-help"></div>
    <modal title="Keyboard Shortcuts"
            id="{{id}}"
            posX="0" posY="0"
            containerWidth="{{wareaWidth * .8}}"
            containerHeight="{{wareaHeight * .8}}"
            minWidth="350px"
            minHeight="400px"
    >
      <div class="keyboard-help-header">
        <button class="keyboard-help-closer" on-click="close-help" title="Close (Esc)">
          ×
        </button>
      </div>

      <div class="keyboard-help-content">
        {{# keybindsData.length > 0 }}
          {{{ keybindsHtml }}}
        {{else}}
          <p class="keyboard-help-empty">No keyboard shortcuts are currently available.</p>
        {{/}}
      </div>
    </modal>
    {{/if}}
    """

})

export default RactiveKeyboardHelp
