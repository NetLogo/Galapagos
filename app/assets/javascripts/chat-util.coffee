# This file contains chat utility functions that don't interact with UI globals,
# SO THIS DAMN WELL BETTER NOT EVER DEPEND ON ANY UI ELEMENTS/UI GLOBALS --JAB 1/25/13

ChatModule = exports.ChatServices.Module
Constants  = exports.ChatConstants
CSS        = exports.CSS
globals    = exports.ChatGlobals

class ChatUtil

  # Return Type: Unit
  extractParamFromURL: (paramName) ->
    params  = window.location.search.substring(1) # `substring` to drop the '?' off of the beginning
    matches = params.match(///(?:&[^&]*)*#{paramName}=([^&]*).*///)
    if (matches and matches.length > 0) then unescape(matches[1]) else ""

  # Return Type: String
  getAmericanizedTime: ->
    date    = new Date()
    hours   = date.getHours()
    minutes = date.getMinutes()

    suffix     = if (hours > 11) then "pm" else "am"
    newHours   = if (hours % 12) is 0 then 12 else (hours % 12)
    newMinutes = (if (minutes < 10) then "0" else "") + minutes

    "#{newHours}:#{newMinutes}#{suffix}"

  # Return Type: Unit
  initAgentList: -> ChatModule.agentList.map((type) -> globals.agentTypes.push(type))

  # Return Type: String
  messageHTMLMaker: (user, context, text, time, kind) ->

    globals.messageCount++

    userColor =
      if user is globals.userName
        CSS.SelfUserColored
      else if globals.agentTypes.indexOf(user) > -1
        CSS.ChannelContextColored
      else
        CSS.OtherUserColored

    userClassStr      = "class='#{CSS.User} #{userColor}'"
    contextClassStr   = "class='#{CSS.Context} #{CSS.ContrastColored}'"
    messageClassStr   = "class='#{CSS.Message} #{CSS.CommonTextColored}'"
    timestampClassStr = "class='#{CSS.Timestamp} #{CSS.ContrastColored}'"
    enhancedText      = @enhanceMsgText(text, kind)

    """
      <div class='#{CSS.ChatMessage} #{CSS.Rounded} #{CSS.BackgroundBackgrounded}'>
        <table>
          <tr>
            <td #{userClassStr}>#{user}</td>
            <td #{contextClassStr}>@#{context}</td>
            <td #{messageClassStr}>#{enhancedText}</td>
            <td #{timestampClassStr}>#{time}</td>
          </tr>
        </table>
      </div>
    """

  # Return Type: String
  enhanceMsgText: (text, kind) ->

    # Sorting the user list enables the name highlighter to properly highlight the name with the longest match
    sortedUsersAsc  = _(globals.usersArr).sortBy((username) -> username.length)
    sortedUsersDesc = sortedUsersAsc.slice(0).reverse() # Slice/clone before reversing, so you don't mutate the original!

    subFunc = (acc, x) =>
      colorClass   = if x is globals.userName then CSS.SelfUserColored else CSS.OtherUserColored
      substitution = @addClassToText("@" + x, colorClass)
      longestMatch = _(sortedUsersDesc).find((name) -> _(name).startsWith(x))
      tail         = longestMatch.substring(x.length)
      regexAppend  = if _(tail).isEmpty() then "" else "(?!#{tail})"
      regex        = ///@#{x}#{regexAppend}///g
      acc.replace(regex, substitution)

    coloredText =
      switch kind
        when "chatter" then _(sortedUsersAsc).foldr(subFunc, text)
        when "join"    then @addClassToText(text, CSS.JoinColored)
        when "quit"    then @addClassToText(text, CSS.QuitColored)
        else                text

    fontifiedText =
      switch kind
        when "chatter", "join", "quit" then @normalFontifyText(coloredText)
        else                                @monospaceFontifyText(coloredText)

    fontifiedText

  # Return Type: String
  normalFontifyText: (text) ->
    @addClassToText(text, CSS.NormalFont)

  # Return Type: String
  monospaceFontifyText: (text) ->
    @addClassToText(text, CSS.MonospaceFont)

  # Return Type: String
  # Could be smarter and check to see if the text were already wrapped in a `span`...
  addClassToText: (text, cssClass) ->
    "<span class='#{cssClass}'>#{text}</span>"

  # Return Type: Unit
  textScroll: (container) ->
    bottom = container[0].scrollHeight - container.height()
    font = container.css('font-size')
    size = parseInt(font.substr(0, font.length - 2))
    container.scrollTop(bottom - size)
    container.animate({'scrollTop': bottom}, 'fast')

  # Enables forced scroll-to-bottom of chat buffer for the next `SCROLL_TIME` milliseconds
  # Return Type: Unit
  tempEnableScroll: ->
    globals.wontScroll = false
    clearTimeout(globals.scrollTimer)
    globals.scrollTimer = setTimeout((-> globals.wontScroll = true), Constants.SCROLL_TIME)

  # Return Type: Int or Event (//@ Yikes!)
  extractCharCode: (e) ->
    if e && e.which
      e.which
    else if window.event
      window.event.which
    else
      e  # Should pretty much never happen

  # Return Type: [String, String, String, String, String, [String*], String]
  parseData: (event) ->
    data    = if (typeof(event.data) == 'string') then JSON.parse(event.data) else event.data

    time    = @getAmericanizedTime()
    user    = data.user
    context = data.context
    message = data.message
    kind    = data.kind
    members = data.members
    error   = data.error

    [time, user, context, message, kind, members, error]

  # Give me streams, or give me crappy code!
  # Return Type: String
  spaceGenerator: (num) -> _([0...num]).foldl(((str) -> str + "&nbsp;"), "")

exports.ChatServices.Util = new ChatUtil
