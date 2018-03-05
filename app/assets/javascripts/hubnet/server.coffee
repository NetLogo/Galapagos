class window.Server
  constructor: (@ioSignalingUrl, @logger, @getViewState) ->
    @dataChannels = { }
    @sendToClient = (message) ->
      logger('Received message from client while not connected as server?')
      logger(message)

  connect: () ->
    @signalingSocket = signalingSocket = io(@ioSignalingUrl)
    @sendToClient = (message) ->
      signalingSocket.emit('to-client', message)
    @signalingSocket.on('to-server', (message) =>
      @handleClientMessage(message)
    )
    @logger('Ready to act as server')
    return

  broadcast: (updates) ->
    if (Object.getOwnPropertyNames(@dataChannels).length > 0 and updates?)
      @sendData("DataSend", updates)
    return

  chunkSize = 32000
  sendData: (type, updates) =>
    deflated = Kompressor.compress(updates)
    messages = Kompressor.split(deflated, chunkSize)
    if messages.length > 99
      throw new Error('We cannot send messages larger than 100 chunks right now sorry :-/')
    # send "begin" message
    for own clientId, clientConnection of @dataChannels
      try
        clientConnection.channel.send(JSON.stringify({ type, count: messages.length }))
      catch e
        @logger("Error beginning send data to client(#{clientId}): #{e}")
    messages.forEach((msg) =>
      for own clientId, clientConnection of @dataChannels
        try
          clientConnection.channel.send(msg)
        catch e
          @logger("Error sending data to client(#{clientId}): #{e}")
    )
    return

  close: () ->
    for clientId, _ of @dataChannels
      @disconnect(clientId)
      @logger('Closed all data channels')

    if (@signalingSocket?)
      @sendToClient({ type: 'server-close' })
      @signalingSocket.close()
      @signalingSocket = null
      @logger('Closed signalling socket')

    return

  disconnect: (clientId) ->
    if (not @dataChannels.hasOwnProperty(clientId))
      @logger("No data channel found to close for #{clientId}")
      return

    client = @dataChannels[clientId]
    client.open = false
    @logger('Closing data channels')
    if(client.channel?)
      client.channel.close()
      @logger("Closed data channel with label: #{client.channel.label}")
      client.channel = null
    if(client.connection?)
      client.connection.close()
      client.connection = null
    @logger("Closed data channel connections for #{clientId}.")
    delete @dataChannels[clientId]
    return

  handleClientMessage: (message) =>
    clientId = message.clientId
    @logger("Server received client (#{clientId}) message: #{message.type}")
    if message.type is 'client-offer'
      @handleClientOffer(clientId, message.desc)
    if message.type is 'client-ice-candidate'
      @dataChannels[clientId].connection.addIceCandidate(message.candidate)
    if message.type is 'client-disconnect'
      @disconnect(clientId)
    return

  handleClientOffer: (clientId, desc) ->
    @logger('Client offer received...')
    connection = new RTCPeerConnection({ offerToReceiveAudio: false })
    connection.onicecandidate = (event) => @iceCallback(clientId, event)
    sendToClient = @sendToClient
    @logger('Created server connection.')

    connection.ondatachannel = (event) => @channelCallback(clientId, event)

    @logger('Setting server remote description from client')
    connection.setRemoteDescription(desc)
    answer = connection.createAnswer()
    .then(
      (desc) => @gotDescription(clientId, desc),
      @onCreateSessionDescriptionError
    )
    .then(() -> sendToClient({
      type: 'client-offer-response',
      desc: connection.localDescription
    }))
    @logger('Server connection answer complete.')

    client = { connection, first: true, errors: 0 }
    @dataChannels[clientId] = client

    return

  channelCallback: (clientId, event) =>
    client = @dataChannels[clientId]
    client.channel = event.channel
    client.channel.onopen = () => @onSendChannelStateChange(clientId)
    client.channel.onclose = () => @onSendChannelStateChange(clientId)
    @logger('Created server channel.')

  iceCallback: (clientId, event) =>
    @logger('ICE callback for the server')
    if (event.candidate)
      @sendToClient({ type: 'server-ice-candidate', candidate: event.candidate })
    return

  onAddIceCandidateSuccess: (clientId) ->
    @logger('AddIceCandidate success.')
    return

  onAddIceCandidateError: (error) ->
    @logger('Failed to add Ice Candidate: ' + error.toString())
    return

  onSendChannelStateChange: (clientId) =>
    client = @dataChannels[clientId]
    if (not client?)
      return
    readyState = client.channel.readyState
    @logger('Send channel state has changed: ' + readyState)
    if (readyState is 'open')
      viewState = @getViewState()
      @sendData("Reset", viewState)
      client.open = true
    else
      @disconnect(clientId)

    return

  #onReceiveMessageCallback: (clientId, event) =>
  #  console.log("Message received from client (#{clientId}).")

  gotDescription: (clientId, desc) =>
    @dataChannels[clientId].connection.setLocalDescription(desc)
    @logger('Completed answer on server: \n' + desc.sdp)
    return

  onCreateSessionDescriptionError: (error) ->
    @logger('Failed to create session description: ' + error.toString())
    return
