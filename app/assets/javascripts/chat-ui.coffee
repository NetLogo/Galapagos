Constants = exports.ChatConstants
CSS       = exports.CSS
$globals  = exports.$ChatGlobals
globals   = exports.ChatGlobals
Util      = new exports.ChatUtil

class exports.ChatUI

  # Return Type: Unit
  send: (message) ->
    globals.socket.send(JSON.stringify({ agentType: $globals.$agentType.text(), cmd: message }))
    globals.messageList.append(message, globals.agentTypes.getCurrent())
    globals.messageList.clearCursor()
    $globals.$inputBuffer.val("")
    @focusInput()

  # Return Type: () -> Unit
  throttledSend: (message) -> _.throttle(@send(message), Constants.THROTTLE_DELAY)

  # Return Type: Unit
  focusInput: -> $globals.$inputBuffer.focus()

  # Caching jQuery selector results for easy access throughout the code
  # Return Type: Unit
  initSelectors: ->
    $globals.$inputBuffer   = $("#inputBuffer")
    $globals.$onlineLog     = $("#onlineLog")
    $globals.$chatLog       = $("#chatLog")
    $globals.$container     = $("#container")
    $globals.$copier        = $("#copier")
    $globals.$textCopier    = $("#textCopier")
    $globals.$agentType     = $("#agentType")
    $globals.$outputState   = $("#outputState")
    $globals.$errorPane     = $("#errorPane")
    $globals.$errorPaneSpan = $("#errorPane span")
    $globals.$chatPane      = $("#chatPane")

  # Return Type: Unit
  updateUserList: (users) ->
    globals.usersArr = users
    $globals.$onlineLog.text("")
    for user in users
      color = if user is globals.userName then CSS.SelfUserColored else CSS.OtherUserColored
      row   =
        """
        <div id='#{user}' onclick='exports.event.changeUsernameBG(this)' class='#{CSS.Username} #{CSS.UsernamePlain}'>
        <div class='#{CSS.UsernameInner}'>
        <span class="#{CSS.UsernameText} #{color}">#{Util.spaceGenerator(3)}#{user}</span>
        </div>
        </div>
        """
      $globals.$onlineLog.append(row)

  # Return Type: Unit
  decideShowErrorOrChat: (error) ->
    if error
      globals.socket.close()
      $globals.$errorPaneSpan.text(error)
      $globals.$errorPane.show()
    else
      $globals.$chatPane.show()

  # Return Type: Unit
  clearChat: ->
    $globals.$chatLog.text('')
    globals.logList = []
    $globals.$inputBuffer.focus()

  # Return Type: Unit
  setAgentTypeIndex: (index) ->
    globals.agentTypes.setCurrentIndex(index)
    $globals.$agentType.text(globals.agentTypes.getCurrent())

  # Return Type: Unit
  setAgentType: -> $globals.$agentType.text(globals.agentTypes.getCurrent())

  # Return Type: Unit
  scroll: (key) ->

    ml = globals.messageList

    if key is 38  # Up arrow
      if ml.cursor
        ml.cursor = if ml.cursor.prev != null then ml.cursor.prev else ml.cursor
      else
        ml.addCurrent($globals.$inputBuffer.val(), globals.agentTypes.getCurrent())
        ml.cursor = ml.head
    else if key is 40  # Down arrow
      ml.cursor = ml.cursor.next

    extractInfoAndType = (source) -> [source.data, source.type]

    [info, type] =
      if ml.cursor
        extractInfoAndType(ml.cursor)
      else
        [info, type] = extractInfoAndType(ml.current)
        ml.clearCursor()
        [info, type]

    globals.agentTypes.setCurrent(type)
    @setAgentType()
    $globals.$inputBuffer.val(info)

