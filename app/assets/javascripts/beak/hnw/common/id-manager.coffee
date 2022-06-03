import { MinID, nextID } from './id.js'

export default class IDManager

  _lastIDMap: undefined # Object[String, Number]

  constructor: ->
    @_lastIDMap = {}

  # (String) => Number
  next: (ident) ->
    lid                = @_lastIDMap[ident]
    out                = if lid? then nextID(lid) else MinID
    @_lastIDMap[ident] = out
    out
