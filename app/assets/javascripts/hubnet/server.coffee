# type HubNetMessage = { clientID: String, data: Object[Any], type: String }

class window.Server

  # (String, (String) => Unit, () => ViewState)
  constructor: (@ioSignalingUrl, @logger, @getViewState) ->
    @dataChannels = {}
    @sendToClient =
      (type, data = {}) ->
        @logger('Received message from client while not connected as server?')
        @logger(message)

  # () => Unit
  connect: ->
    @signalingSocket = io(@ioSignalingUrl)
    @sendToClient    = (type, data = {}) => @signalingSocket.emit('to-client', { data, type })
    @signalingSocket.on('to-server', (message) => @handleClientMessage(message))
    @logger('Ready to act as server')
    return

  # (Array[Update]) => Unit
  broadcast: (updates) ->
    if Object.getOwnPropertyNames(@dataChannels).length > 0 and updates?
      @sendData("DataSend", updates)
    return

  # (String, Any) => Unit
  sendData: (type, data) =>

    chunkSize = 32000
    deflated  = Kompressor.compress(data)
    messages  = Kompressor.chunk(deflated, chunkSize)

    if messages.length > 99
      throw new Error('We cannot send messages larger than 100 chunks right now sorry :-/')

    for own clientID, clientConnection of @dataChannels
      try clientConnection.channel.send(JSON.stringify({ type, count: messages.length }))
      catch e
        @logger("Error beginning send data to client(#{clientID}): #{e}")

    messages.forEach(
      (msg) =>
        for own clientID, clientConnection of @dataChannels
          try clientConnection.channel.send(msg)
          catch e
            @logger("Error sending data to client(#{clientID}): #{e}")
    )

    return

  # () => Unit
  close: ->

    for clientID, _ of @dataChannels
      @disconnect(clientID)
      @logger('Closed all data channels')

    if (@signalingSocket?)
      @sendToClient('server-close')
      @signalingSocket.close()
      @signalingSocket = null
      @logger('Closed signalling socket')

    return

  # (String) => Unit
  disconnect: (clientID) ->

    if @dataChannels.hasOwnProperty(clientID)

      client      = @dataChannels[clientID]
      client.open = false
      @logger('Closing data channels')

      if client.channel?
        client.channel.close()
        @logger("Closed data channel with label: #{client.channel.label}")
        client.channel = null

      if client.connection?
        client.connection.close()
        client.connection = null

      @logger("Closed data channel connections for #{clientID}.")
      delete @dataChannels[clientID]

    else
      @logger("No data channel found to close for #{clientID}")

    return

  # (HubNetMessage) => Unit
  handleClientMessage: ({ clientID, data, type }) =>
    @logger("Server received client (#{clientID}) message: #{type}")
    switch type
      when 'client-offer'
        @handleClientOffer(clientID, data.desc)
      when 'client-ice-candidate'
        @dataChannels[clientID].connection.addIceCandidate(data.candidate)
      when 'client-disconnect'
        @disconnect(clientID)
    return

  # (String, RTCSessionDescription) => Unit
  handleClientOffer: (clientID, desc) ->

    # (RTCPeerConnectionIceEvent) => Unit
    iceCallback =
      ({ candidate }) =>
        @logger('ICE callback for the server')
        if candidate?
          @sendToClient('server-ice-candidate', { candidate })
        return

    # (RTCSessionDescription) => Unit
    gotDescription =
      (desc) =>
        @dataChannels[clientID].connection.setLocalDescription(desc)
        @logger("Completed answer on server:\n#{desc.sdp}")
        return

    # (Error) => Unit
    onCreateSessionDescriptionError =
      (error) ->
        @logger("Failed to create session description: #{JSON.stringify(error)}")
        return

    @logger('Client offer received...')
    connection = new RTCPeerConnection({ offerToReceiveAudio: false })
    connection.onicecandidate = (event) => iceCallback(event)
    @logger('Created server connection.')
    connection.ondatachannel  = (event) => @channelCallback(clientID, event)

    @logger('Setting server remote description from client')
    connection.setRemoteDescription(desc)
    connection.createAnswer()
      .then(gotDescription, onCreateSessionDescriptionError)
      .then(=> @sendToClient('client-offer-response', { desc: connection.localDescription }))
    @logger('Server connection answer complete.')

    client = { connection, first: true, errors: 0 }
    @dataChannels[clientID] = client

    return

  # (String, RTCDataChannelEvent) => Unit
  channelCallback: (clientID, event) =>

    openChannel =
      =>
        if @dataChannels[clientID]?
          @logger("Opening channel...")
          @sendData("Reset", @getViewState())
          @dataChannels[clientID].open = true
        return

    closeChannel =
      =>
        if @dataChannels[clientID]?
          @logger("Closing channel...")
          @disconnect(clientID)
        return

    client                 = @dataChannels[clientID]
    client.channel         = event.channel
    client.channel.onopen  =  openChannel
    client.channel.onclose = closeChannel
    @logger('Created server channel.')

    return
