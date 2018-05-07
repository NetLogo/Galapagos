isMac            = window.navigator.platform.startsWith('Mac')
platformCtrlHtml = if isMac then "&#8984;" else "ctrl"

window.RactiveHelpDialog = Ractive.extend({

  data: -> {
    isOverlayUp: undefined # Boolean
  , isVisible:   undefined # Boolean
  , stateName:   undefined # String
  , wareaHeight: undefined # Number
  , wareaWidth:  undefined # Number
  }

  observe: {
    isVisible: (newValue, oldValue) ->
      @set('isOverlayUp', newValue)
      if newValue
        setTimeout((=> @find("#help-dialog").focus()), 0) # Dialog isn't visible yet, so can't be focused --JAB (5/2/18)
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

  }

  # coffeelint: disable=max_line_length
  template:
    """
    <div id="help-dialog" class="help-popup"
         style="{{# !isVisible }}display: none;{{/}} top: {{(wareaHeight * .1) + 150}}px; left: {{wareaWidth * .1}}px; height: {{wareaHeight * .8}}px; width: {{wareaWidth * .8}}px; {{style}}"
         on-keydown="handle-key" tabindex="0">
      <div id="{{id}}-closer" class="widget-edit-closer" on-click="close-popup">X</div>
      <div>{{>helpText}}</div>
    </div>
    """
  # coffeelint: enable=max_line_length

  partials: {

    helpAuthoringEditWidget:
      """
      <li><kbd>enter</kbd> - submit form</li>
      <li><kbd>escape</kbd> - close form and ignore any changes made</li>
      """

    helpAuthoringStandard:
      """
      <li>#{platformCtrlHtml}+<kbd>shift</kbd>+<kbd>alt</kbd>+<kbd>i</kbd> - switch to interactive mode</li>
      <li>#{platformCtrlHtml}+<kbd>shift</kbd>+<kbd>h</kbd> - toggle resizer visibility</li>
      <li><kbd>escape</kbd> - close context menu if it is open; deselect a widget that is selected</li>
      <li>#{platformCtrlHtml} - hold to ignore "snap to grid" while moving or resizing this widget</li>
      <li>{{# !isMac }}<kbd>delete</kbd> - delete the widget{{/}}</li>
      <li><kbd>&uarr;/&darr;/&larr;/&rarr;</kbd> - move widget, agnostic of grid</li>
      """

    helpInteractive:
      """
      <li>#{platformCtrlHtml}+<kbd>shift</kbd>+<kbd>alt</kbd>+<kbd>i</kbd> - switch to authoring mode</li>
      """

    helpText:
      """
      <ul>
        {{# stateName === 'interactive' }}
          {{>helpInteractive}}
        {{elseif stateName === 'authoring - plain' }}
          {{>helpAuthoringStandard}}
        {{elseif stateName === 'authoring - editing widget' }}
          {{>helpAuthoringEditWidget}}
        {{else}}
          Invalid help state.
        {{/}}
      </ul>
      """

  }

})
