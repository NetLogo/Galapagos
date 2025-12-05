import { isMac } from "./utils.js"
import { KeyCombo } from "./key-combo.js"

# Keybind[mousetrap, ractive]
# mousetrap: Mousetrap
# ractive: Ractive
export class Keybind
  id: undefined     # String
  cb: undefined     # (ractive, KeyboardEvent, combo) => Boolean | Unit
  combos: undefined # Array[KeyCombo]
  metadata: {}      # { description: String, docs: String, hidden?: Boolean }
  options: {}       # { type: "keydown" | "keyup" | "keypress", bind: Boolean, preventDefault: Boolean }

  # parameters:
  # id: String
  # cb: (ractive, KeyboardEvent, combo) => Boolean | Unit
  # comboStrs: Array[String] (see https://craig.is/killing/mice; excluding sequences)
  # metadata: { description: String, docs: String } | undefined
  # options: { type: "keydown" | "keyup" | "keypress", bind: Boolean, preventDefault: Boolean } | undefined
  constructor: (@id, @cb, comboStrs, @metadata, options) ->
    @options = { type: "keydown", bind: true, preventDefault: false, ...options }
    @combos = comboStrs.map((comboStr) -> new KeyCombo(comboStr))
    Object.defineProperty(this, 'comboStrs', {
      get: => @combos.map((combo) -> combo.comboStr)
    })

  # (mousetrap, ractive, ((ractive) => Boolean) | undefined) => Unit
  bind: (mousetrap, ractive, check) ->
    if @options.bind is true
      mousetrap.bind(@comboStrs, (e, combo) =>
        if not check or check(ractive) and @cb?
          if @options.preventDefault and e.preventDefault?
            e.preventDefault()
          return @cb(ractive, e, combo)
      , @options.type)

  # (mousetrap) => Unit
  unbind: (mousetrap) ->
    if @options.bind is true
      mousetrap.unbind(@comboStrs, @options.type)

# KeybindGroup[mousetrap, ractive]
# mousetrap: Mousetrap
# ractive: Ractive
export class KeybindGroup
  # name: String
  # description: String | undefined
  # conditions: Array[((ractive) => Boolean)]
  # keybinds (keybinds): Array[Keybind]
  constructor: (name, description, conditions, keybinds) ->
    @name = name
    @description = description
    @conditions = conditions
    @keybinds = keybinds

  # ractive => Boolean
  meetsConditions: (ractive) ->
    return @conditions.every((condition) => condition(ractive))

  # (mousetrap, ractive) => Unit
  bind: (mousetrap, ractive) ->
    @keybinds.forEach((keybind) =>
      keybind.bind(mousetrap, ractive, @meetsConditions.bind(this))
    )

  # (mousetrap) => Unit
  unbind: (mousetrap) ->
    @keybinds.forEach((keybind) -> keybind.unbind(mousetrap))
