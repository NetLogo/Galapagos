window.connect = (socketURL) ->
  new Connection(new WebSocket(socketURL))

class Connection
  constructor: (@socket) ->
    @listeners = {'all': []}
    @outbox = [] # Messages that someone tried to send before the socket opened
    @socket.onmessage = (event) => @dispatch(JSON.parse(event.data))
    @socket.onopen = => @send(msg) for msg in @outbox


  send: (message) ->
    if @socket.readyState == @socket.OPEN
      @socket.send(JSON.stringify(message))
    else
      @outbox.push(message)

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
