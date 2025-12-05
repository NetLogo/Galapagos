import { isMac } from "./utils.js"

class KeyCombo
  # (String) => Unit
  constructor: (comboStr) ->
    @comboStr = comboStr
    [@key, parts...] = comboStr.toLowerCase().split('+').map((x) => x.trim()).reverse()
    @modifiers = {
        ctrl:  parts.includes('ctrl')  or parts.includes('control')
      , alt:   parts.includes('alt')   or parts.includes('option')
      , shift: parts.includes('shift')
      , meta:  parts.includes('meta')  or parts.includes('cmd') or parts.includes('command') or parts.includes('mod')
    }

  # { [key: String]: String }
  keyStringTable: {
    up: "↑",
    down: "↓",
    left: "←",
    right: "→",
    escape: "Esc",
  }

  # () => Array[String]
  getKeys: ->
    modifierKeys = Object.entries(@modifiers).filter(([_, v]) => v).map(([mod, _]) =>
      switch mod
        when 'ctrl'  then if isMac then 'Control' else 'Ctrl'
        when 'alt'   then if isMac then '⌥'  else 'Alt'
        when 'shift' then '⇧'
        when 'meta'  then if isMac then '⌘'  else 'Meta'
    )

    mainKey = if Object.prototype.hasOwnProperty.call(@keyStringTable, @key)
      @keyStringTable[@key]
    else
      @key[0].toUpperCase() + @key.slice(1).toLowerCase()

    [...modifierKeys, mainKey]

  # () => String
  toString: ->
    @getKeys().join(' + ')

export { KeyCombo }
