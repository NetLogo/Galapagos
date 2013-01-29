ChatModule  = new exports.ChatModule
Keybindings = new exports.ChatKeybindings
UI          = new exports.ChatUI
Util        = new exports.ChatUtil

$globals    = exports.$ChatGlobals
globals     = exports.ChatGlobals

TextHolder  = exports.TextHolder

# Onload
document.body.onload = ->

  UI.initSelectors()
  Util.initAgentList()

  globals.userName = Util.extractParamFromURL("username")
  $globals.$agentType.text(globals.agentTypes.getCurrent())

  WS = if window['MozWebSocket'] then MozWebSocket else WebSocket
  globals.socket = new WS(socketURL)

  globals.socket.onmessage = (event) ->

    [time, user, context, message, kind, members, dataError] = Util.parseData(event)
    UI.decideShowErrorOrChat(dataError)

    if message
      switch kind
        when 'update'
          updateModel = JSON.parse(message)
          controller.update(updateModel)
        when 'js', 'model_update'
          updateSet = JSON.parse(ChatModule.runJS(message))
          for update in updateSet
            controller.update(update)
        else
          globals.logList[globals.messageCount] = new TextHolder(message)
          difference = $globals.$container[0].scrollHeight - $globals.$container.scrollTop()
          $globals.$chatLog.append(Util.messageHTMLMaker(user, context, message, time, kind))
          if difference is $globals.$container.innerHeight() or not globals.wontScroll or user is globals.userName then Util.textScroll($globals.$container)
          #TODO Only call for joins and leaves
          UI.updateUserList(members)

  Keybindings.initKeybindings()

