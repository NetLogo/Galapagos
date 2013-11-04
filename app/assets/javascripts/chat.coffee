ChatModule  = exports.ChatServices.Module
Keybindings = exports.ChatServices.Keybindings
UI          = exports.ChatServices.UI
Util        = exports.ChatServices.Util

$globals    = exports.$ChatGlobals
globals     = exports.ChatGlobals

TextHolder  = exports.TextHolder

exports.initChat = (session) ->
  UI.setupUI()
  #Util.initAgentList()

  globals.userName = Util.extractParamFromURL("username") or globals.tortoiseUser
  UI.setAgentType()

  handleChatEvent = (msg) ->
    if msg.message != ""
      handleChatMessage(msg.user, msg.context, msg.message, msg.members,
        Util.getAmericanizedTime(), msg.kind)

  handleChatMessage = (user, context, message, members, time, kind) ->
    globals.logList[globals.messageCount] = new TextHolder(message)
    difference = $globals.$container[0].scrollHeight - $globals.$container.scrollTop()
    $globals.$chatLog.append(Util.messageHTMLMaker(user, context, message, time, kind))
    if difference is $globals.$container.innerHeight() or not globals.wontScroll or user is globals.userName then Util.textScroll($globals.$container)
    #TODO Only call for joins and leaves
    UI.updateUserList(members)

  session.connection.on('all',      (msg) -> UI.decideShowErrorOrChat(msg.error))
  session.connection.on('join',     handleChatEvent)
  session.connection.on('quit',     handleChatEvent)
  session.connection.on('chatter',  handleChatEvent)
  session.connection.on('command',  handleChatEvent)
  session.connection.on('response', handleChatEvent)

  globals.session = session

  receiveMessage = (event) ->
    if messageOriginValid(event.origin)
      message = JSON.parse(event.data)
      if message.agentType? and message.cmd?
        UI.run(message.agentType, message.cmd)
      else
        console.error("Received invalid message:\n#{event}")

  messageOriginValid = (origin) ->
    # TODO Origin validation, lest we be subject to XSS attacks
    true

  window.addEventListener('message', receiveMessage, false)

  Keybindings.initKeybindings()
