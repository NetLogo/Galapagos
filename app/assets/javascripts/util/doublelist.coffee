class ListNode
  constructor: (@data, @type) ->
    @next = null
    @prev = null

class DoubleList

  constructor: (@maxLen) ->
    @len = 0
    @head = null
    @tail = null
    @cursor = null
    @current = null

  # Return Type: Unit
  clearCursor: ->
    @cursor = null
    @current = null

  # Return Type: Unit
  addCurrent: (cmd, agentType) ->
    @current = new ListNode(cmd, agentType)

  # Return Type: Unit
  append: (text, type) ->

    newNode = new ListNode(text, type)

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

exports.DoubleList = DoubleList
