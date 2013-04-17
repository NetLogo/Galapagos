# This file contains functions related to keybindings (preferably utilizing Mousetrap.js)

$globals = exports.$ChatGlobals
globals  = exports.ChatGlobals
UI       = exports.ChatServices.UI
Util     = exports.ChatServices.Util

class ChatKeybindings

  # This sets keybindings for most of the interface, and for `#chatterInput`
  # However, the keybindings that are active while the Command Center has focus are handled by Ace/`globals.ccEditor`
  # If you want to set a keybinding for the Command Center, don't set it here; seek out where Ace is initialized!
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
      UI.sendInput()
      Util.tempEnableScroll()
    )

    Mousetrap.bind('up', (e) ->
      if e.target.id is 'chatterBuffer'
        UI.scrollMessageListUp()
    )

    Mousetrap.bind('down', (e) ->
      if e.target.id is 'chatterBuffer'
        UI.scrollMessageListDown()
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
