class CommandCenterModel
  constructor: (@user, @modes) ->
    @inputHistory = []
    @messageList = []
    @_startNewMessage()

  _startNewMessage: ->
    @newMessage = @currentMessage = new Message(@user, @mode(), '')
    @_inputIndex = @inputHistory.length

  edit: (text) ->
    @currentMessage.text = text

  mode: -> 
    if @currentMessage? then @currentMessage.mode else @modes[0]

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
    if (@inputHistory.length == 0 or
        not @currentMessage.equal(@inputHistory[@inputHistory.length - 1]))
      @inputHistory.push(@currentMessage)
    @_startNewMessage()
    message

  prevInput: ->
    if @_inputIndex > 0
      @currentMessage = @inputHistory[--@_inputIndex].clone()
    @currentMessage

  nextInput: ->
    if @_inputIndex < @inputHistory.length - 1
      @currentMessage = @inputHistory[++@_inputIndex].clone()
    else if @_inputIndex == @inputHistory.length - 1
      @_inputIndex = @inputHistory.length
      @currentMessage = @newMessage
    @currentMessage

  addMessage: (message) ->
    @messageList.append(message)

  
class Message
  constructor: (@user, @mode, @text) ->

  clone: ->
    return new Message(@user, @mode, @text)

  equal: (other) ->
    if not other instanceof Message
      false
    else
      @user == other.user && @mode == other.mode && @text == other.text

exports.Message = Message
exports.CommandCenterModel = CommandCenterModel
    


    
