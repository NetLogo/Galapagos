exports.connect = (sucketURL) ->
  new Connection(new WebSocket(socketURL))

class Connection
  constructor: (@socket) ->
    @listeners = {}
    @socket.onmessage = (event) => @dispatch(event.data)

  send: (message) ->
    @socket.send(JSON.stringify(message))

  dispatch: (msg) ->
    for listener in @listeners[msg.kind]
      listener(msg)

  on: (kind, listener) ->
    if not listener[kind]?
      listener[kind] = []
    listener[kind].push(listener)
