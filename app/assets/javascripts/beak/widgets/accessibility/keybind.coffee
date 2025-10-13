import { isMac } from "./utils.js"
import { KeyCombo } from "./key-combo.js"

export class Keybind
  # id: string
  # cb: (ractive, KeyboardEvent, combo) => Boolean | Unit
  # comboStrs: https://craig.is/killing/mice (excluding sequences)
  # metadata: { description: String, docs: String } | undefined
  # options: { type: "keydown" | "keyup" | "keypress", bind: Boolean, preventDefault: Boolean }
  constructor: (
    id, cb, comboStrs, metadata = {},
    options = {}
  ) ->
    @id = id
    @cb = cb
    @metadata = metadata
    @options = { type: "keydown", bind: true, preventDefault: false, ...options }
    @combos = comboStrs.map((comboStr) -> new KeyCombo(comboStr))
    Object.defineProperty(this, 'comboStrs', {
      get: => @combos.map((combo) -> combo.comboStr)
    })

  # (Mousetrap, ractive) => Unit
  bind: (mousetrap, ractive, check) ->
    if @options.bind isnt true
      return

    mousetrap.bind(@comboStrs, (e, combo) =>
      if not check or check(ractive) and @cb?
        if @options.preventDefault
          e.preventDefault()
        return @cb(ractive, e, combo)
    , @options.type)

  # (Mousetrap) => Unit
  unbind: (mousetrap) ->
    if @options.bind isnt true
      return
    mousetrap.unbind(@comboStrs, @options.type)

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

  # (Mousetrap, ractive) => Unit
  bind: (mousetrap, ractive) ->
    @keybinds.forEach((keybind) =>
      keybind.bind(mousetrap, ractive, @meetsConditions.bind(this))
    )

  # (Mousetrap) => Unit
  unbind: (mousetrap) ->
    @keybinds.forEach((keybind) -> keybind.unbind(mousetrap))
