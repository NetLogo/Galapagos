import { MaxID, MinID, precedesID, prevID, succeedsID } from './id.js'

# type MessageHandler = (Object[Any]) => Unit

dummyID = -2 # Number

export default class MessageQueue

  _handleMessage: undefined # MessageHandler
  _isStarted:     undefined # Boolean
  _lastMsgID:     undefined # Number
  _predIDToMsg:   undefined # Object[UUID, Any]

  # (MessageHandler) => MessageQueue
  constructor: (@_handleMessage) ->
    @_isStarted   = false
    @_lastMsgID   = dummyID
    @_predIDToMsg = {}

  # (Object[Any]) => Unit
  enqueue: (msg) ->

    lastMsgID   = @_lastMsgID
    msgID       = msg.id
    predIDToMsg = @_predIDToMsg

    if not @_isStarted and msgID is MinID
      @_isStarted = true
      @_lastMsgID = msgID
      @_handleMessage(msg)

    else if succeedsID(msgID, lastMsgID)

      # If looping around, clear any junk in the queue --Jason B. (12/2/21)
      if msgID is MinID and lastMsgID > MinID
        newQueue = {}
        if precedesID(lastMsgID, MaxID) or lastMsgID is MaxID
          for i in [lastMsgID..MaxID]
            if predIDToMsg[i]?
              newQueue[i] = predIDToMsg[i]
        @_predIDToMsg = newQueue

      @_predIDToMsg[prevID(msgID)] = msg
      @_processQueue()

    else
      # coffeelint: disable=max_line_length
      s = "Received message ##{msgID} when the last-processed message was ##{lastMsgID}.  ##{msgID} is out-of-order and will be dropped:"
      # coffeelint: enable=max_line_length
      console.warn(s, msg)

    return

  # () => Unit
  _processQueue: ->

    lastMsgID   = @_lastMsgID
    predIDToMsg = @_predIDToMsg

    successor = predIDToMsg[lastMsgID]

    if successor?
      delete predIDToMsg[lastMsgID]
      @_lastMsgID = successor.id
      @_handleMessage(successor)
      @_processQueue()

    return
