class CommandCenterModel
  constructor: (@user, @modes) ->
    @inputHistory = new DoubleList()
    @messageList = []
    @currentMode = if modes.length > 0 then modes[0] else ''
    @_startNewMessage()

  _startNewMessage: ->
    @currentMessage = new Message(@user, @currentMode, '')
    @inputHistory.append(@currentMessage)
    @inputHistory.clearCursor()

  edit: (text) ->
    @currentMessage.text = text

  setMode: (mode) ->
    @currentMode = mode
    @currentMessage.mode = mode

  send: (message) ->
    @inputHistory.head = @currentMessage
    @_startNewMessage()

  prevInput: ->
    @currentMessage = @inputHistory.moveCursorBack().clone()

  nextInput: ->
    @currentMessage = @inputHistory.moveCursorForward().clone()

  addMessage: (message) ->
    @messageList.append(message)

  
class Message
  constructor: (@user, @mode, @text) ->

  clone: ->
    return new Message(@user, @mode, @text)

  
    


    
