class CommandCenter
  constructor: (options) ->
    @options =
      username: 'You'
      modes: ['observer', 'turtles', 'patches', 'links']
      textModes: ['chatter']
      
    for key, val of options
      @options[key] = val

    @model = new CommandCenterModel(@options.username, @options.modes)
    @ui = new CommandCenterUI()

  getInput: -> @ui.getInput()

  sendInput: -> 
    @model.edit(@getInput())
    @model.send()

  edit: (text) -> @model.edit(text)

  _handleModeChange: ->
    if @options.textModes.indexOf(@model.mode()) > -1
      @ui.useTextInput()
    else
      @ui.useCodeInput()
    @ui.setInput(@model.getInput())
    @ui.setPromp(@model.mode())
    @model.mode()

  nextInput: -> 
    @model.edit(@getInput())
    @model.nextInput()
    @_handleModeChange()

  prevInput: -> 
    @model.edit(@getInput())
    @model.prevInput()
    @_handleModeChange()

  nextMode: ->
    @model.nextMode()
    @_handleModeChange()
    
  prevMode: -> 
    @model.prevMode()
    @_handleModeChange()

  setModeIndex: (index) ->
    @model.setModeIndex(index)
    @_handleModeChange()
    
class CommandCenterUI
  constructor: () ->
    @$prompt = $('#agentType')
    @activeInput = 'text'  # should be 'text' or 'code'
    @codeInput = globals.ccEditor
    @$codeInputWrapper = $('#codeBufferWrapper')
    @$textInput = $('#chatterBuffer')

  setPrompt: (promptText) -> @$prompt.text(promptText)

  setInput: (newInput) ->
    @$textInput.val(newInput)
    @codeInput.setValue(newInput)
    @codeInput.clearSelection()

  getInput: ->
    if @activeInput == 'text' then @$textInput.val() else @codeInput.getValue()

  _focusTextInput: -> $textInput.focus()

  _focusCodeInput: -> codeInput.focus()

  useTextInput: ->
    @activeInput = 'text'
    $codeInputWrapper.hide()
    $textInput.show()
    color = $textInput.css('background-color')
    $textInput.parent().css('background-color', color)
    @_focusTextInput()
  
  useCodeInput: ->
    @activeInput = 'code'
    $textInput.hide()
    $codeInputWrapper.css('display', 'block')
    color = $codeInputWrapper.children('.ace_scroller')
                             .children('.ace_marker-layer')
                             .children('.ace_active-line')
                             .css('background-color')
    if color != 'rgba(0, 0, 0, 0)' and color != 'transparent'
      $textInput.parent().css('background-color', color)
    @_focusCodeInput()




    
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
#exports.CommandCenterModel = CommandCenterModel
exports.CommandCenter = CommandCenter
    


    
