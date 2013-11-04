class DoubleList

  constructor: (@maxLen) ->
    @len = 0
    @head = null
    @tail = null
    @cursor = null

  class Node
    constructor: (@data) ->
      @next = null
      @prev = null

  # returns: undefined
  clearCursor: ->
    @cursor = @head
    return

  # returns: undefined
  append: (data) ->

    newNode = new Node(data)

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

  moveCursorBack: ->
    if not @cursor?
      @cursor = @head
    if @cursor.prev?
      @cursor = @cursor.prev
    @cursor.data

  moveCursorForward: ->
    if not @cursor?
      @cursor = @head
    if @cursor.next?
      @cursor = @cursor.next
    @cursor.data

exports.DoubleList = DoubleList
