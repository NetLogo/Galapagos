isMac            = window.navigator.platform.startsWith('Mac')
platformCtrlHtml = if isMac then "&#8984;" else "ctrl"

# (Array[String], String) => String
keyRow =
  (keys, explanation) ->
    """<tr>
         <td class="help-keys">#{keys.map((key) -> "<kbd>" + key + "</kbd>").join('')}</td>
         <td class="help-explanation">#{explanation}</td>
       </tr>"""

# (Array[Array[Array[String], String]]) => String
keyTable =
  (entries) ->
    """<table class="help-key-table">
         #{entries.map(([keys, explanation]) -> keyRow(keys, explanation)).join('\n')}
       </table>"""

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
         style="{{# !isVisible }}display: none;{{/}} top: {{(wareaHeight * .1) + 150}}px; left: {{wareaWidth * .1}}px; width: {{wareaWidth * .8}}px; {{style}}"
         on-keydown="handle-key" tabindex="0">
      <div id="{{id}}-closer" class="widget-edit-closer" on-click="close-popup">X</div>
      <div>{{>helpText}}</div>
    </div>
    """

  partials: {

    helpAuthoringEditWidget:
      keyTable([
        [["enter" ], "submit form"]
      , [["escape"], "close form and ignore any changes made"]
      ])

    helpAuthoringStandard:
      keyTable([
        [[platformCtrlHtml, "shift", "l"        ], "switch to interactive mode"]
      , [[platformCtrlHtml, "shift", "h"        ], "toggle resizer visibility"]
      , [["escape"                              ], "close context menu if it is open, or deselect any selected widget"]
      , [[platformCtrlHtml                      ], "hold to ignore \"snap to grid\" while moving or resizing the selected widget"]
      , [["&uarr;", "&darr;", "&larr;", "&rarr;"], "move widget, irrespective of the grid"]
      ].concat(if not isMac then [[["delete"], "delete the selected widget"]] else []))

    helpInteractive:
      keyTable([
        [[platformCtrlHtml, "shift", "l"], "switch to authoring mode"]
      , [[platformCtrlHtml, "u"         ], "find all usages of selected text (when in NetLogo Code editor)"]
      , [[platformCtrlHtml, ";"         ], "comment/uncomment a line of code (when in NetLogo Code editor)"]
      ])

    helpText:
      """
      <table>
        {{# stateName === 'interactive' }}
          {{>helpInteractive}}
        {{elseif stateName === 'authoring - plain' }}
          {{>helpAuthoringStandard}}
        {{elseif stateName === 'authoring - editing widget' }}
          {{>helpAuthoringEditWidget}}
        {{else}}
          Invalid help state.
        {{/}}
      </table>
      """

  }
  # coffeelint: enable=max_line_length

})
