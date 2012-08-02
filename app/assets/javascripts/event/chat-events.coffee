###
Event handlers
###

event =

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
        $textCopier.hide()  # Hide to avoid ghostly scrollbar issue on Chrome/Safari (on Mac OS)
        $textCopier.val(finalText)

    # Return Type: Unit
    textCollapse: (row) ->
      textObj = logList[row.id]
      [middle, others...] = row.getElementsByClassName('middle')
      textObj.change()
      middle.innerHTML = textObj.toString()


  ###
  Basic event functionality
  ###

  # Return Type: Unit
  clearChat: ->
    $chatLog.text('')
    state = 0
    logList = []
    $inputBuffer.focus()

  # Return Type: Unit
  nameSelect: (id) ->
    row = $("#{id}")
    row.css({backgroundColor: '#0033CC', color: '#FFFFFF', fontWeight: 'bold'})

  # Return Type: Unit
  nameDeselect: (id) ->
    row = $('#{id}')
    row.css({backgroundColor: '#FFFFFF', color: '#000000', fontWeight: 'normal'})

  # Return Type: Unit
  copySetup: (text) ->
    $copier.attr('name', text)
    $copier.val(text)
    $copier.focus()
    $copier.select()

  # Return Type: Boolean
  handleTextRowOnMouseUp: (row) ->
    @util.getSelText()
    if $textCopier.val() is ''
      @util.textCollapse(row)
      $container.focus()
    false

# Final export of module
exports.event = exports.event ? event
