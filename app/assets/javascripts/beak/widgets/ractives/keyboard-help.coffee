import RactiveModal from './subcomponent/modal.js'

RactiveKeyboardHelp = Ractive.extend({

  data: -> {
    id: "keyboard-help-dialog"
    isVisible: false
    isOverlayUp: false
    wareaHeight: 600
    wareaWidth: 600
    keybinds: [] # see accessibility/keybinds.js for structure – Omar I. (Oct 13 2025)
  }

  # () => Unit
  generateGroups: ->
    groups = @get('keybinds')
    if not groups or groups.length is 0
      return

    groups = groups.map((g) =>
      keybinds = (g.keybinds or []).map((kb) ->
        description = kb.metadata?.description or 'No description available'
        combos = (kb.combos or []).map((combo) -> { keys: combo.getKeys() })
        { description: description, combos: combos }
      )
      disabled = not g.meetsConditions(@root)
      { name: g.name, description: g.description, keybinds, disabled }
    )

    @set('groups', groups)
    return

  observe: {
    isVisible: (newValue) ->
      @set('isOverlayUp', newValue)
      if newValue
        @generateGroups()
        setTimeout((=> @find('#keyboard-help-dialog')?.focus?()), 0)
        @fire('dialog-opened', this)
      else
        @fire('dialog-closed', this)
      return
  }

  on: {
    'close-help': ->
      @set('isVisible', false)
      return

    'handle-key': ({ original: { key } }) ->
      if key is "Escape"
        @fire('close-help')
        false
  }

  # () => Unit
  show: ->
    @set('isVisible', true)
    return

  # () => Unit
  hide: ->
    @set('isVisible', false)
    return

  components: {
    modal: RactiveModal
  }

  partials: {
    keybindRow: """
    <tr>
      <td class="keyboard-help-key">
        <div class="keyboard-help-multiple">
          {{#combos}}
            <div class="keyboard-help-single">
              {{#keys}}
                <kbd>{{.}}</kbd>
              {{/keys}}
            </div>
          {{/combos}}
        </div>
      </td>
      <td class="keyboard-help-description">{{description}}</td>
    </tr>
    """

    closeButton: """
    <button class="keyboard-help-closer" on-click="close-help" title="Close (Esc)">
      ×
    </button>
    """
  }

  template:
    """
    {{#isVisible }}
    <div class="keyboard-help-backdrop" on-click="close-help"></div>
    <modal title="Keyboard Shortcuts"
            id="{{id}}"
            posX="0" posY="0"
            containerWidth="{{wareaWidth}}"
            containerHeight="{{wareaHeight}}"
            minWidth="350px"
            minHeight="400px"
    >
      <div class="keyboard-help-header">
        {{>closeButton}}
      </div>

      <div class="keyboard-help-content">
        {{# groups.length > 0 }}
          <table class="keyboard-help-table">
            <thead>
              <tr>
                <th>Key Combination</th>
                <th>Action</th>
              </tr>
            </thead>
            {{#groups}}
              {{#unless disabled}}
              <tr>
                <th colspan="2">
                  <div class="keyboard-help-group-header">
                    <h3 class="keyboard-help-group-title">{{name}}</h3>
                    {{#if description}}<p class="keyboard-help-group-description">{{description}}</p>{{/if}}
                  </div>
                </th>
              </tr>

              {{#keybinds}}
                {{>keybindRow .}}
              {{/keybinds}}
              {{/unless}}
            {{/groups}}
          </table>
        {{else}}
          <p class="keyboard-help-empty">No keyboard shortcuts are currently available.</p>
        {{/}}
      </div>
    </modal>
    {{/}}
    """
})

export default RactiveKeyboardHelp
