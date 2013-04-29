window.connect = (socketURL) ->
  new Connection(new WebSocket(socketURL))

class Connection
  constructor: (@socket) ->
    @listeners = {'all': []}
    @socket.onmessage = (event) => @dispatch(JSON.parse(event.data))

  send: (message) ->
    @socket.send(JSON.stringify(message))

  dispatch: (msg) ->
    for listener in @listeners['all']
      listener(msg)
    if not @listeners[msg.kind]?
      @listeners[msg.kind] = []
    for listener in @listeners[msg.kind]
      listener(msg)

  on: (kind, listener) ->
    if not @listeners[kind]?
      @listeners[kind] = []
    @listeners[kind].push(listener)
