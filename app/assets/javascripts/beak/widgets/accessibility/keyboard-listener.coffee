class KeyboardListener
  constructor: ->
    @keybinds = new Map() # Map<KeyCombo, { callback: (event: KeyboardEvent) => Unit }>

  # () => Unit
  register: ->
    window.addEventListener('keyup', @handleKeyup.bind(this), true)

  # () => Unit
  unregister: ->
    window.removeEventListener('keyup', @handleKeyup.bind(this), true)

  # (event: KeyboardEvent) => Boolean
  handleKeyup: (event) ->
    @keybinds.forEach(({ callback }, combo) ->
      if combo.matchesEvent(event)
        callback(event)
        event.preventDefault()
        return false
    )
    return true

  # String, ((event: KeyboardEvent) => Unit) => Unit
  bindKey: (comboStr, callback, id, metadata = {}) ->
    try
      combo = new KeyCombo(comboStr)
      @keybinds.set(combo, { callback, id, metadata })
    catch error
      console.error("Failed to bind key combo '#{comboStr}': #{error.message}")
    return

  # String, ((event: KeyboardEvent) => Unit | undefined) => Unit
  unbindKey: (comboStr, callback) ->
    if typeof callback isnt 'undefined'
      if @keybinds.get(comboStr)?.callback is callback
        @keybinds.delete(comboStr)
    else
      @keybinds.delete(comboStr)
    return

  # (String, String) => Unit
  remap: (id, comboStr) ->
    entry = Array.from(@keybinds).find(([, { id: entryId }]) => entryId is id)
    if entry?
      [oldCombo, { callback, id, metadata }] = entry
      @keybinds.delete(oldCombo)
      try
        newCombo = new KeyCombo(comboStr)
        @keybinds.set(newCombo, { callback, id, metadata })
      catch error
        console.error("Failed to remap key combo '#{comboStr}': #{error.message}")
    return

export createKeyMetadata = (defaultComboStr, description, docs) ->
  return Object.freeze({
    defaultComboStr, description, docs
  })

isMac = window.navigator.platform.startsWith('Mac')

class KeyCombo
  # (String) => Unit
  constructor: (comboStr) ->
    @comboStr = comboStr
    parts   = comboStr.toLowerCase().split('+').map((x) => x.trim())
    @key    = parts.pop()
    @modifiers = {
      ctrl:  parts.includes('ctrl')  or parts.includes('control')
      , alt:   parts.includes('alt')   or parts.includes('option')
      , shift: parts.includes('shift')
      , meta:  parts.includes('meta')  or parts.includes('cmd') or parts.includes('command')
    }
    @digitKey = @key.length is 1 and @key.match(/[0-9]/)

    modifierCount = Object.values(@modifiers).filter((x) => x).length
    if 1 + modifierCount isnt parts.length + 1
      throw new Error("Invalid key combo string: #{@comboStr}")

  # KeyboardEvent => Boolean
  matchesEvent: (event) ->
    return false if @digitKey and event.code isnt "Digit#{@key}"
    return false if event.key.toLowerCase() isnt @key and not @digitKey
    return false if event.ctrlKey  isnt @modifiers.ctrl
    return false if event.altKey   isnt @modifiers.alt
    return false if event.shiftKey isnt @modifiers.shift
    return false if event.metaKey  isnt @modifiers.meta
    return true

  # () => String
  toString: -> [
    ...Object.entries(@modifiers).filter(([_, v]) => v).map(([mod, _]) =>
      if      mod is 'ctrl'  then (if isMac then 'Control' else 'Ctrl')
      else if mod is 'alt'   then (if isMac then '⌥'  else 'Alt')
      else if mod is 'shift' then '⇧'
      else if mod is 'meta'  then (if isMac then '⌘'  else 'Meta')
    ),
    @key[0].toUpperCase() + @key.slice(1).toLowerCase()
  ].join(' + ')


RactiveKeyboardListener = Ractive.extend({
  keyboardListener: new KeyboardListener()

  on: {
    init: ->
        @keyboardListener.register()

    teardown: ->
        @keyboardListener.unregister()
  }

  template:
    """
    <div class="netlogo-keyboard-listener hidden"></div>
    """
})

export default RactiveKeyboardListener
