# This file contains functions related to keybindings (preferably utilizing Mousetrap.js)

$globals = exports.$ChatGlobals
globals  = exports.ChatGlobals
UI       = exports.ChatServices.UI
Util     = exports.ChatServices.Util

class ChatKeybindings

  # Return Type: Unit
  initKeybindings: ->

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

    Mousetrap.bind(
      'tab',
      ((e) ->
        e.preventDefault()
        UI.nextAgentType()),
      'keydown'
    )

    Mousetrap.bind(keyArray, (-> UI.focusInput()), 'keydown')

    Mousetrap.bind('enter', (e) ->
      input = $globals.$inputBuffer.val()
      UI.throttledSend(input) if e.target.id is 'inputBuffer' and /\S/g.test(input)
      Util.tempEnableScroll()
    )

    Mousetrap.bind(['up', 'down'], (e) ->
      if e.target.id is 'inputBuffer'
        charCode = Util.extractCharCode(e)
        e.preventDefault()
        UI.scroll(charCode)
    )

    Mousetrap.bind('space', (e) ->
      if e.target.id is 'container'
        e.preventDefault()
        Util.textScroll($globals.$container)
        UI.focusInput()
    )

    Mousetrap.bind(ctrlArr.concat(cmdArr), (e) ->
      num = Util.extractCharCode(e) - 48  # This will get us keyboard number pressed (1/2/3/4/5)
      e.preventDefault()
      UI.setAgentTypeIndex(num - 1)
    )

    Mousetrap.bind('ctrl+l', (-> UI.clearChat()))

    Mousetrap.bind('pageup', (-> $globals.$container.focus()))

exports.ChatServices.Keybindings = new ChatKeybindings
