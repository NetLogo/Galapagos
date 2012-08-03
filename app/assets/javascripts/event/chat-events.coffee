###
Event handlers
###

event =

  $globals: exports.$chatGlobals
  globals:  exports.chatGlobals

  ###
  Event-handling utilities
  ###

  util:

    # Credit to Jeff Anderson
    # Source: http://www.codetoad.com/javascript_get_selected_text.asp
    # Return Type: Unit
    getSelText: ->

      txt = window.getSelection() ? document.getSelection() ? document.selection?.createRange().text

      if txt
        # The regular expression 'timestamp' matches time strings of the form hh:mm in 24-hour format.
        timestamp = /// \t(
           (?:
             (?:[0-1][0-9])
            |(?:2[0-3])
           ):[0-5][0-9]
        )$ ///gm

        modText = txt.toString().replace(timestamp, "   [$1]")
        finalText = modText.replace(/\t/g, "   ")
        $globals.$textCopier.hide()  # Hide to avoid ghostly scrollbar issue on Chrome/Safari (on Mac OS)
        $globals.$textCopier.val(finalText)

    # Return Type: Unit
    textCollapse: (row) ->
      textObj = globals.logList[row.id]
      [middle, others...] = row.getElementsByClassName('middle')
      textObj.change()
      middle.innerHTML = textObj.toString()


  ###
  Basic event functionality
  ###

  # Return Type: Unit
  clearChat: ->
    $globals.$chatLog.text('')
    state = 0
    globals.logList = []
    $globals.$inputBuffer.focus()

  # Return Type: Unit
  nameSelect: (id) ->
    row = $("#{id}")
    row.css({backgroundColor: '#0033CC', color: '#FFFFFF', fontWeight: 'bold'})

  # Return Type: Unit
  nameDeselect: (id) ->
    row = $("#{id}")
    row.css({backgroundColor: '#FFFFFF', color: '#000000', fontWeight: 'normal'})

  # Return Type: Unit
  copySetup: (text) ->
    $globals.$copier.attr('name', text)
    $globals.$copier.val(text)
    $globals.$copier.focus()
    $globals.$copier.select()

  # Return Type: Boolean
  handleTextRowOnMouseUp: (row) ->
    @util.getSelText()
    if $globals.$textCopier.val() is ''
      @util.textCollapse(row)
      $globals.$container.focus()
    false

# Final export of module
exports.event = exports.event ? event
