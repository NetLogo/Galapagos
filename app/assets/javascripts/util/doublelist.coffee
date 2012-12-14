class DoubleList

  constructor: (@maxLen) ->
    @len = 0
    @head = null
    @tail = null
    @cursor = null
    @current = null

  class Node
    constructor: (@data, @type) ->
      @next = null
      @prev = null

  # returns: undefined
  clearCursor: ->
    @cursor = null
    @current = null
    return

  # returns: undefined
  addCurrent: (cmd, agentType) ->
    @current = new Node(cmd, agentType)
    return

  # returns: undefined
  append: (text, type) ->

    newNode = new Node(text, type)

    if @head
      newNode.prev = @head
      @head.next = newNode

    @head = newNode
    @tail = @head if not @tail

    if (@len < @maxLen)
      @len++
    else
      @tail      = @tail.next
      @tail.prev = null

    return

exports.DoubleList = DoubleList
