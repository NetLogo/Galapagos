Constants = exports.ChatConstants
CSS       = exports.CSS
$globals  = exports.$ChatGlobals
globals   = exports.ChatGlobals
Util      = exports.ChatServices.Util

commandCenter = new exports.CommandCenterModel(globals.userName, globals.agentTypes)

class ChatUI

  # Return Type: (String) -> Unit
  throttle = _.throttle(((message) -> exports.ChatServices.UI.send(message)), Constants.THROTTLE_DELAY)

  # Return Type: String
  getInput: =>
    @ifChatterElse(-> $globals.$chatterBuffer.val())(-> globals.ccEditor.getValue())

  # Return Type: Unit
  setInput: (newInput) =>
    @ifChatterElse(-> $globals.$chatterBuffer.val(newInput))(-> ed = globals.ccEditor; ed.setValue(newInput); ed.clearSelection())

  # Return Type: Unit
  focusInput: ->
    @ifChatterElse(-> $globals.$chatterBuffer.focus())(-> globals.ccEditor.focus())

  # Return Type: Any
  ifChatterElse: (f) -> (g) ->
    if commandCenter.mode() is 'chatter' then f() else g()

  # Return Type: Unit
  send: (message) ->
    @run(message.mode, message.text)
    @setInput("")
    @focusInput()

  # Return Type: Unit
  run: (agentType, cmd) ->
    globals.session.run(agentType, cmd)

  # Return Type: Unit
  sendInput: ->
    #input = @getInput()
    commandCenter.edit(@getInput())
    input = commandCenter.send()
    if /\S/g.test(input) then throttle(input)
    Util.tempEnableScroll()

  # Caching jQuery selector results for easy access throughout the code
  # Return Type: Unit
  initSelectors = ->
    $globals.$codeBufferWrapper  = $("#codeBufferWrapper")
    $globals.$chatterBuffer      = $("#chatterBuffer")
    $globals.$inputsWrapper      = $("#inputsWrapper")
    $globals.$onlineLog          = $("#onlineLog")
    $globals.$chatLog            = $("#chatLog")
    $globals.$container          = $("#container")
    $globals.$agentType          = $("#agentType")
    $globals.$outputState        = $("#outputState")
    $globals.$errorPane          = $("#errorPane")
    $globals.$errorPaneSpan      = $("#errorPane span")
    $globals.$chatPane           = $("#chatPane")

  # Return Type: Unit
  updateUserList: (users) ->
    globals.usersArr = users
    if $globals.$onlineLog.length > 0
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
    @focusInput()

  # Return Type: Unit
  setAgentTypeIndex: (index) ->
    commandCenter.setModeIndex(index)
    @setAgentType()

  # Return Type: Unit
  nextAgentType: ->
    commandCenter.nextMode()
    @setAgentType()

  # Return Type: Unit
  setAgentType: ->
    input = @getInput()
    $globals.$agentType.text(commandCenter.mode())
    @refreshWhichInputElement()
    @setInput(input)

  # Return Type: Unit
  refreshWhichInputElement: ->

    BGColorPropName = 'background-color'

    $chatter = $globals.$chatterBuffer
    $code    = $globals.$codeBufferWrapper

    @ifChatterElse(
      =>
        $code.hide()
        $chatter.show()
        color = $chatter.css(BGColorPropName)
        $chatter.parent().css(BGColorPropName, color)
        @focusInput()
    )(
      =>
        $chatter.hide()
        $code.css('display', 'block')
        color = $code.children(".ace_scroller").children(".ace_content").children(".ace_marker-layer").children(".ace_active-line").css(BGColorPropName)
        if color != "rgba(0, 0, 0, 0)" and color != "transparent"
          $chatter.parent().css(BGColorPropName, color)
        @focusInput()
    )

  # Return Type: Unit
  scrollMessageListUp: ->
    commandCenter.edit(@getInput())
    commandCenter.prevInput()
    @scrollMessageList()

  # Return Type: Unit
  scrollMessageListDown: ->
    commandCenter.nextInput()
    @scrollMessageList()

  # Return Type: Unit
  scrollMessageList: ->
    exports.ChatServices.UI.setAgentType()
    exports.ChatServices.UI.setInput(commandCenter.currentMessage.text)

  # Return Type: Unit
  setupUI: ->
    globals.ccEditor.renderer.$renderChanges() # Force early initialization of Ace, so it's ready when we make it visible
    initSelectors()
    @setupPhonyInput()

  # Return Type: Unit
  setupPhonyInput: ->

    $wrapper = $globals.$inputsWrapper
    $chatter = $globals.$chatterBuffer
    $editor  = $globals.$codeBufferWrapper.children(".ace_text-input").first()

    glowClass   = CSS.Glow

    $wrapper.focus(=>
      @ifChatterElse(=>
        $chatter.focus()
      )(=>
        $editor.focus()
      )
    )

    subInputs = [$chatter, $editor]
    _(subInputs).forEach(($elem) ->
      $elem.focus(=>
        $wrapper.addClass(glowClass)
      ).blur(=>
        removeIfSafe = -> if not _(subInputs).find(($elem) -> $elem.is(":focus")) then $wrapper.removeClass(glowClass)
        setTimeout(removeIfSafe, 100) # Removing a class seems to take significantly longer than adding one, so first wait and verify that it needs to go
      )
    )

exports.ChatServices.UI = new ChatUI
