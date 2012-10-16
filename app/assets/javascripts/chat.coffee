###
Created with JetBrains WebStorm.
User: Joe
Date: 6/22/12
Time: 4:50 PM
###

# Imports
TextHolder = exports.TextHolder
DoubleList = exports.DoubleList
CircleMap  = exports.CircleMap
CSS        = exports.CSS

THROTTLE_DELAY = 100
SCROLL_TIME    = 500

# Variables into which to cache jQuery selector results
$globals =
  $inputBuffer:   undefined
  $onlineLog:     undefined
  $chatLog:       undefined
  $container:     undefined
  $copier:        undefined
  $textCopier:    undefined
  $agentType:     undefined
  $outputState:   undefined
  $errorPane:     undefined
  $errorPaneSpan: undefined
  $chatPane:      undefined

# Other globals
globals =
  userName:      undefined
  usersArr:      undefined
  socket:        undefined
  scrollTimer:   undefined
  wontScroll:    true
  messageCount:  0
  messageList:   new DoubleList(20)
  agentTypeList: new CircleMap()
  logList:       []


exports.$chatGlobals = $globals
exports.chatGlobals  = globals

# Onload
document.body.onload = ->

  initSelectors()
  initAgentList()

  globals.userName = extractParamFromURL("username")
  $globals.$agentType.text(globals.agentTypeList.getCurrent())
  throttledSend = _.throttle(send, THROTTLE_DELAY)

  WS = if window['MozWebSocket'] then MozWebSocket else WebSocket
  globals.socket = new WS(socketURL)

  updateUserList = (users) ->
    globals.usersArr = users
    $globals.$onlineLog.text("")
    for user in users
      color = if user is globals.userName then CSS.SelfUserColored else CSS.OtherUserColored
      row   =
        """
        <div id='#{user}' onclick='exports.event.changeUsernameBG(this)' class='#{CSS.Username} #{CSS.UsernamePlain}'>
          <div class='#{CSS.UsernameInner}'>
            <span class="#{CSS.UsernameText} #{color}">#{spaceGenerator(3)}#{user}</span>
          </div>
        </div>
        """
      $globals.$onlineLog.append(row)

  globals.socket.onmessage = (event) ->

    data = JSON.parse(event.data)
    decideShowErrorOrChat(data)

    d       = new Date()
    time    = getAmericanizedTime()
    user    = data.user
    context = data.context
    message = data.message
    kind    = data.kind

    if message
      globals.logList[globals.messageCount] = new TextHolder(message)
      difference = $globals.$container[0].scrollHeight - $globals.$container.scrollTop()
      $globals.$chatLog.append(messageHTMLMaker(user, context, message, time, kind))
      if difference is $globals.$container.innerHeight() or not globals.wontScroll or user is globals.userName then textScroll()

    updateUserList(data.members)

  keyString =
      'abcdefghijklmnopqrstuvwxyz' +
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
      '1234567890!@#$%^&*()' +
      '\<>-_=+[{]};:",.?\\|\'`~'
  keyArray = keyString.split('')

  AgentTypeCount = 5
  agentTypeNumArr = [1..AgentTypeCount]

  numMorpher = (modifier) -> (num) -> modifier + "+shift+" + num
  ctrlArr    = agentTypeNumArr[0..].map(numMorpher("ctrl"))
  cmdArr     = agentTypeNumArr[0..].map(numMorpher("command"))

  Mousetrap.bind('tab', (e) ->
    e.preventDefault()
    globals.agentTypeList.next()
    setAgentType()
  , 'keydown')

  Mousetrap.bind(keyArray, (-> focusInput()), 'keydown')

  Mousetrap.bind('enter', (e) ->
    input = $globals.$inputBuffer.val()
    throttledSend(input) if e.target.id is 'inputBuffer' and /\S/g.test(input)
    tempEnableScroll()
  )

  Mousetrap.bind(['up', 'down'], (e) ->
    if e.target.id is 'inputBuffer'
      charCode = extractCharCode(e)
      e.preventDefault()
      scroll(charCode)
  )

  Mousetrap.bind('space', (e) ->
    if e.target.id is 'container' or e.target.id is 'copier'
      e.preventDefault()
      textScroll()
      focusInput()
  )

  Mousetrap.bind(ctrlArr.concat(cmdArr), (e) ->
    num = extractCharCode(e) - 48  # This will get us keyboard number pressed (1/2/3/4/5)
    e.preventDefault()
    setAgentTypeIndex(num - 1)
  )

  Mousetrap.bind('ctrl+l', (-> clearChat()))

  Mousetrap.bind('pageup', (-> $globals.$container.focus()))


###
Basic page functionality
###

# Caching jQuery selector results for easy access throughout the code
# Return Type: Unit
initSelectors = ->
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
initAgentList = ->
  agentTypes = ['chatter', 'observer', 'turtles', 'patches', 'links']
  agentTypes.map((type) -> globals.agentTypeList.append(type))

# Return Type: Unit
decideShowErrorOrChat = (data) ->
  if data.error
    globals.socket.close()
    $globals.$errorPaneSpan.text(data.error)
    $globals.$errorPane.show()
  else
    $globals.$chatPane.show()

# Return Type: String
messageHTMLMaker = (user, context, text, time, kind) ->

  globals.messageCount++

  userColor =
    if user is globals.userName
      CSS.SelfUserColored
    else if globals.agentTypeList.contains(user)
      CSS.ChannelContextColored
    else
      CSS.OtherUserColored

  userClassStr      = "class='#{CSS.User} #{userColor}'"
  contextClassStr   = "class='#{CSS.Context} #{CSS.ContrastColored}'"
  messageClassStr   = "class='#{CSS.Message} #{CSS.CommonTextColored}'"
  timestampClassStr = "class='#{CSS.Timestamp} #{CSS.ContrastColored}'"
  enhancedText      = enhanceMsgText(text, kind)

  """
    <div class='#{CSS.ChatMessage} #{CSS.Rounded} #{CSS.BackgroundBackgrounded}'>
      <table>
        <tr>
          <td #{userClassStr}>#{user}</td>
          <td #{contextClassStr}>@#{context}</td>
          <td #{messageClassStr}>#{enhancedText}</td>
          <td #{timestampClassStr}>#{time}</td>
        </tr>
    </div>
  """

# Return Type: Unit
extractParamFromURL = (paramName) ->
  params = window.location.search.substring(1) # `substring` to drop the '?' off of the beginning
  unescape(params.match(///(?:&[^&]*)*#{paramName}=([^&]*).*///)[1])

# Return Type: String
getAmericanizedTime = ->
  date    = new Date()
  hours   = date.getHours()
  minutes = date.getMinutes()

  suffix     = if (hours > 11) then "pm" else "am"
  newHours   = if (hours % 12) is 0 then 12 else (hours % 12)
  newMinutes = (if (minutes < 10) then "0" else "") + minutes

  "#{newHours}:#{newMinutes}#{suffix}"

# Return Type: String
enhanceMsgText = (text, kind) ->
  subFunc = (acc, x) ->
    substitution = colorifyText("@" + x, if x is globals.userName then CSS.SelfUserColored else CSS.OtherUserColored)
    acc.replace(///@#{x}///g, substitution)
  switch kind
    when "chatter" then _.foldl(globals.usersArr, subFunc, text)
    when "join"    then colorifyText(text, CSS.JoinColored)
    when "quit"    then colorifyText(text, CSS.QuitColored)
    else                text

# Return Type: String
colorifyText = (text, cssClass) ->
  "<span class='#{cssClass}'>#{text}</span>"

# Return Type: Unit
clearChat = ->
  $globals.$chatLog.text('')
  state = 0
  globals.logList = []
  $globals.$inputBuffer.focus()

# Return Type: Unit
textScroll = ->
  bottom = $globals.$container[0].scrollHeight - $globals.$container.height()
  font = $globals.$container.css('font-size')
  size = parseInt(font.substr(0, font.length - 2))
  $globals.$container.scrollTop(bottom - size)
  $globals.$container.animate({'scrollTop': bottom}, 'fast')

# Enables forced scroll-to-bottom of chat buffer for the next `SCROLL_TIME` milliseconds
# Return Type: Unit
tempEnableScroll = ->
  globals.wontScroll = false
  clearTimeout(globals.scrollTimer)
  globals.scrollTimer = setTimeout((-> globals.wontScroll = true), SCROLL_TIME)

# Return Type: Int or Event (//@ Yikes!)
extractCharCode = (e) ->
  if e && e.which
    e.which
  else if window.event
    window.event.which
  else
    e  # Should pretty much never happen

# Return Type: Unit
setAgentTypeIndex = (index) ->
  globals.agentTypeList.setCurrentIndex(index)
  $globals.$agentType.text(globals.agentTypeList.getCurrent())

# Return Type: Unit
setAgentType = ->
  $globals.$agentType.text(globals.agentTypeList.getCurrent())

# Return Type: Unit
scroll = (key) ->

  ml = globals.messageList

  if key is 38  # Up arrow
    if ml.cursor
      ml.cursor = if ml.cursor.prev != null then ml.cursor.prev else ml.cursor
    else
      ml.addCurrent($globals.$inputBuffer.val(), globals.agentTypeList.getCurrent())
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

  globals.agentTypeList.setCurrent(type)
  setAgentType()
  $globals.$inputBuffer.val(info)

# Return Type: Unit
send = (message) ->
  globals.socket.send(JSON.stringify({ agentType: $globals.$agentType.text(), cmd: message }))
  globals.messageList.append(message, globals.agentTypeList.getCurrent())
  globals.messageList.clearCursor()
  $globals.$inputBuffer.val("")
  focusInput()

# Return Type: Unit
focusInput = -> $globals.$inputBuffer.focus()

# Give me streams, or give me crappy code!
# Return Type: String
spaceGenerator = (num) -> _.foldl([0...num], ((str) -> str + "&nbsp;"), "")