DoubleList = exports.DoubleList

class CommandCenterModel
  constructor: (@user, @modes) ->
    @inputHistory = new DoubleList(20)
    @messageList = []
    @_startNewMessage()

  _startNewMessage: ->
    @currentMessage = new Message(@user, @modes[0], '')
    @inputHistory.append(@currentMessage)
    @inputHistory.cursorToHead()

  edit: (text) ->
    @currentMessage.text = text

  mode: -> 
    @currentMessage.mode

  modeIndex: ->
    @modes.indexOf(@mode())

  nextMode: ->
    @setModeIndex(@modeIndex() + 1)

  prevMode: ->
    @setModeIndex(@modeIndex() - 1)

  setModeIndex: (i) ->
    @currentMessage.mode = @modes[i % @modes.length]
    
  send: ->
    message = @currentMessage
    @inputHistory.head.data = @currentMessage
    @_startNewMessage()
    message

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

exports.Message = Message
exports.CommandCenterModel = CommandCenterModel
    


    
