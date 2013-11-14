window.exports = window.exports or {}

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
    @_hookUpInputs()
    @_handleModeChange()

  _hookUpInputs: ->
    @ui.prompt.addEventListener('click', => @nextMode())

  getInput: -> @ui.getInput()

  sendInput: -> 
    @_updateModelInput()
    msg = @model.send()
    @edit('')
    @ui.focusInput()
    msg

  edit: (text) -> 
    @ui.setInput(text)
    @model.edit(text)

  _updateModelInput: ->
    @model.edit(@getInput())

  _handleModeChange: ->
    if @options.textModes.indexOf(@model.mode()) > -1
      @ui.useTextInput()
    else
      @ui.useCodeInput()
    @ui.setInput(@model.currentMessage.text)
    @ui.setPrompt(@model.mode())
    @model.mode()

  nextInput: -> 
    @_updateModelInput()
    @model.nextInput()
    @_handleModeChange()

  prevInput: -> 
    @_updateModelInput()
    @model.prevInput()
    @_handleModeChange()

  nextMode: ->
    @_updateModelInput()
    @model.nextMode()
    @_handleModeChange()
    
  prevMode: -> 
    @_updateModelInput()
    @model.prevMode()
    @_handleModeChange()

  setModeIndex: (index) ->
    @_updateModelInput()
    @model.setModeIndex(index)
    @_handleModeChange()
    
class CommandCenterUI
  constructor: () ->
    @prompt = document.createElement('button')
    @prompt.classList.add('agent_type_text', 'rounded', 'background_background', 'full_height', 'full_width', 'no_border')
    @prompt.style.color = 'white'
    @activeInput = 'text'
    @textInput = document.createElement('input')
    @textInput.classList.add('mousetrap', 'cc_input', 'chatter_input', 'normal_font', 'no_glow')
    document.querySelector('#inputsWrapper').appendChild(@textInput)
    document.querySelector('#agentTypeCell').appendChild(@prompt)
    ## TODO: should create element
    #@$prompt = $('#agentType')
    #@activeInput = 'text'  # should be 'text' or 'code'
    ## TODO: should create element
    #@codeInput = exports.ChatGlobals.ccEditor
    ## TODO: should create element
    #@$codeInputWrapper = $('#codeBufferWrapper')
    ## TODO: should create element
    #@$textInput = $('#chatterBuffer')

  setPrompt: (promptText) -> #@$prompt.text(promptText)
    @prompt.textContent = promptText

  setInput: (newInput) ->
    #@$textInput.val(newInput)
    @textInput.value = newInput
    #@codeInput.setValue(newInput)
    #@codeInput.clearSelection()

  getInput: ->
    if @activeInput == 'text' then @textInput.value else @codeInput.getValue()

  focusInput: ->
    if @activeInput == 'text'
      @_focusTextInput()
    else
      #@_focusCodeInput()
      @_focusTextInput()

  _focusTextInput: -> @textInput.focus()

  _focusCodeInput: -> @codeInput.focus()

  useTextInput: ->
    @activeInput = 'text'
    #@$codeInputWrapper.hide()
    #@$textInput.show()
    #color = @$textInput.css('background-color')
    #@$textInput.parent().css('background-color', color)
    @_focusTextInput()
  
  useCodeInput: ->
    @useTextInput()
    #@activeInput = 'code'
    #@$textInput.hide()
    #@$codeInputWrapper.css('display', 'block')
    #color = @$codeInputWrapper.children('.ace_scroller')
    #                          .children('.ace_marker-layer')
    #                          .children('.ace_active-line')
    #                          .css('background-color')
    #if color != 'rgba(0, 0, 0, 0)' and color != 'transparent'
    #  @$textInput.parent().css('background-color', color)
    #@_focusCodeInput()

    
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
    @currentMessage.mode = @modes[((i % @modes.length) + @modes.length) % @modes.length]
    
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
exports.CommandCenter = CommandCenter
exports.CommandCenterModel = CommandCenterModel

