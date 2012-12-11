class MapNode
  constructor: (@key) ->
    @next = null

class CircleMap

  constructor: ->
    @head = null
    @last = null
    @current = null

  # returns: String
  # http://stackoverflow.com/questions/368280/javascript-hashmap-equivalent
  hash = (value) ->
    if value instanceof Object
      (value.__hash ? (value.__hash = 'object ' + ++arguments.callee.current))
    else
      (typeof value) + ' ' + String(value)

  # returns: undefined
  append: (nodeKey) ->
    newNode = new MapNode(nodeKey)
    this[hash(newNode.key)] = newNode
    if @head
      @last.next = newNode
      newNode.next = @head
      @last = newNode
    else
      @head = newNode
      @last = newNode
      @current = newNode
    return

  # returns: Boolean
  contains: (key) ->
    this[hash(key)] != undefined

  # returns: String
  getCurrent: ->
    @current.key

  # returns: undefined
  setCurrent: (key) ->
    @current = this[hash(key)]
    return

  # returns: undefined
  setCurrentIndex: (index) ->
    @current = @head
    @current = @current.next for [1..index]
    return

  # returns: undefined
  next: ->
    @current = @current.next
    return

exports.CircleMap = CircleMap
