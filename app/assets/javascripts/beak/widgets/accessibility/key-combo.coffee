import { isMac } from "./utils.js"

export class KeyCombo
  # (String) => Unit
  constructor: (comboStr) ->
    @comboStr = comboStr
    parts   = comboStr.toLowerCase().split('+').map((x) => x.trim())
    @key    = parts.pop()
    @modifiers = {
      ctrl:  parts.includes('ctrl')  or parts.includes('control')
      , alt:   parts.includes('alt')   or parts.includes('option')
      , shift: parts.includes('shift')
      , meta:  parts.includes('meta')  or parts.includes('cmd') or parts.includes('command') or parts.includes('mod')
    }

  # Print methods
  # { String: String }
  keyStringTable: {
    'up': "↑",
    'down': "↓",
    'left': "←",
    'right': "→",
    'escape': "Esc",
  }

  # Array[String]
  getKeys: -> [
    ...Object.entries(@modifiers).filter(([_, v]) => v).map(([mod, _]) =>
      if      mod is 'ctrl'  then (if isMac then 'Control' else 'Ctrl')
      else if mod is 'alt'   then (if isMac then '⌥'  else 'Alt')
      else if mod is 'shift' then '⇧'
      else if mod is 'meta'  then (if isMac then '⌘'  else 'Meta')
    ),
    if Object.prototype.hasOwnProperty.call(@keyStringTable, @key) then @keyStringTable[@key] else
      @key[0].toUpperCase() + @key.slice(1).toLowerCase()
  ]

  # () => String
  toString: ->
    @getKeys().join(' + ')
