class MapNode
  constructor: (@type) ->
    @next = null

class CircleMap

  constructor: ->
    @head = null
    @last = null
    @current = null

  # Return Type: Unit
  append: (nodeType) ->
    newNode = new MapNode(nodeType)
    hashKey = @hash(newNode.type)
    this[hashKey] = newNode
    if @head
      @last.next = newNode
      newNode.next = @head
      @last = newNode
    else
      @head = newNode
      @last = newNode
      @current = newNode

  # Return Type: String
  hash: (value) ->
    if value instanceof Object
      (value.__hash ? (value.__hash = 'object ' + ++arguments.callee.current))
    else
      (typeof value) + ' ' + String(value)

  # Return Type: MapNode
  get: (type) ->
    hashKey = @hash(type)
    this[hashKey]

  # Return Type: Boolean
  contains: (type) ->
    hashKey = @hash(type)
    this[hashKey] != undefined

  # Return Type: String
  getCurrent: ->
    @current.type

  # Return Type: Unit
  setCurrent: (type) ->
    @current = this[@hash(type)]

  # //@ Slow operation...
  # Return Type: Unit
  setCurrentIndex: (index) ->
    i = index + 1
    @current = @head
    @current = @current.next while i -= 1

  # Return Type: Unit
  next: ->
    @current = @current.next

exports.CircleMap = CircleMap

