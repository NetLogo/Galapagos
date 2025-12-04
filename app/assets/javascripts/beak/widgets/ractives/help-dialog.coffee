RactiveHelpDialog = Ractive.extend({

  data: -> {
    isOverlayUp:      undefined # Boolean
  , isVisible:        undefined # Boolean
  , wareaHeight:      undefined # Number
  , wareaWidth:       undefined # Number
  # see type KeybindGroup from ./accessibility/keybinds.js
  , keybindGroups:    undefined # Array[KeybindGroup]
  }

  # () => Unit
  generateGroups: ->
    groups = @get('keybindGroups')
    if not groups or groups.length is 0
      return

    groups = groups.map((g) =>
      keybinds = (g.keybinds or []).filter((kb) ->
        not kb.metadata?.hidden
      ).map((kb) ->
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
    isVisible: (newValue, oldValue) ->
      @set('isOverlayUp', newValue)
      if newValue
        @generateGroups()
        # Dialog isn't visible yet, so can't be focused --Jason B. (5/2/18)
        setTimeout((=> @find("#help-dialog").focus()), 0)
        @fire('dialog-opened', this)
      else
        @fire('dialog-closed', this)
      return
  }

  on: {
    'close-popup': ->
      @set('isVisible', false)
      false

    'handle-key': ({ original: { keyCode } }) ->
      if keyCode is 27
        @fire('close-popup')
        false

    'keybinds-updated': ->
      if @get('isVisible')
        @generateGroups()
      return
  }

  # () => Unit
  show: ->
    @set('isVisible', true)
    return

  # () => Unit
  hide: ->
    @set('isVisible', false)
    return

  # coffeelint: disable=max_line_length
  template:
    """
    <div id="help-dialog" class="help-popup"
         style="{{# !isVisible }}{{>hidden}}{{/}} {{>position}} {{>dimensions}} {{style}}"
         on-keydown="handle-key" tabindex="0">
      <div>{{>helpText}}</div>
    </div>
    """

  partials: {
    hidden: """display: none; pointer-events: none;"""
    position: """position: absolute; top: {{(wareaHeight * .1) + 150}}px; left: {{wareaWidth * .1}}px;"""
    dimensions: """height: {{wareaHeight * .8}}px; width: {{wareaWidth * .8}}px;"""
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
    <button id="{{id}}-closer" class="widget-edit-closer" on-click="close-popup">X</button>
    """

    helpText:
      """
      <div class="keyboard-help-content">
        {{# groups.length > 0 }}
          <table class="keyboard-help-table">
            <thead>
              <tr>
                <th>Key Combination</th>
                <th>Action</th>
                {{>closeButton}}

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
      """

  }
  # coffeelint: enable=max_line_length

})

export default RactiveHelpDialog
