class window.Client
  constructor: (@ioSignalingUrl, @logger, @notifyClientView, @resetClientViewState, @notifyDisconnect) ->
    @sendToServer = (message) ->
      @logger('Received message from server while not connected as client?')
      @logger(message)
    @state = "Disconnected"

  connect: () ->
    @signalingSocket = signalingSocket = io(@ioSignalingUrl)

    @sendToServer = (message) ->
      message.clientId = signalingSocket.id
      signalingSocket.emit('to-server', message)

    @signalingSocket.on('to-client', @handleServerMessage)

    # RTC BEGIN
    @logger('Creating RTC data channel connection...')
    connection = new RTCPeerConnection({ offerToReceiveAudio: false })
    @connection = connection
    @logger('Created client connection.')
    connection.onicecandidate = @iceCallback

    @channel = connection.createDataChannel('sendDataChannel', null)
    @channel.onopen = @onReceiveChannelStateChange
    # @channel.onclose = @onReceiveChannelStateChange
    @channel.onmessage = @onReceiveMessageCallback

    sendToServer = @sendToServer
    connection.createOffer()
    .then(@gotDescription, @onCreateSessionDescriptionError)
    .then(() ->
      sendToServer({
        type: 'client-offer',
        desc:  connection.localDescription
      })
      return
    )
    # RTC END

    @logger('Signaling complete.')
    return

  disconnect: () ->
    if (@channel? and @channel.readyState is 'open')
      @messageStack = ''
      @logger('Closing data channels')
      @channel.close()
      @logger('Closed data channel with label: ' + @channel.label)
      @channel = null

    if (@connection?)
      @connection.close()
      @logger('Closed connection')
      @connection = null

    if (@signalingSocket?)
      @signalingSocket.close()
      @signalingSocket = null
      @logger('Closed signalling socket')

    @logger('Completed disconnecting.')
    @sendToServer({ type: 'client-disconnect' })
    return

  handleServerMessage: (message) =>
    if message.type is 'client-offer-response'
      @logger('Setting client remote description from server')
      @connection.setRemoteDescription(message.desc)
    if message.type is 'server-ice-candidate'
      @connection.addIceCandidate(message.candidate)
    if message.type is 'server-close'
      @logger('Apparently the server is rudely closing down; disconnecting.')
      @disconnect()
      @notifyDisconnect()
    return

  iceCallback: (event) =>
    @logger('ICE callback on the client.')
    if (event.candidate)
      @sendToServer({ type: 'client-ice-candidate', candidate: event.candidate })
    return

  onAddIceCandidateSuccess: () ->
    @logger('AddIceCandidate success.')
    return

  onAddIceCandidateError: (error) ->
    @logger('Failed to add Ice Candidate: ' + error.toString())
    return

  onReceiveMessageCallback: (event) =>
    @logger('Message received on client.')
    if (not @channel? or not @channel.open is 'open')
      @logger('Received message while not open... weird.')
      return
    switch @state
      when 'Ready'   then @handleInitMessage(JSON.parse(event.data))
      when 'Receive' then @handleReceive(event.data, @notifyClientView)
      when 'Reset'   then @handleReceive(event.data, @resetClientViewState)
    return

  handleInitMessage: (event) =>
    switch event.type
      when "DataSend"
        @messageStack = []
        @messageCount = event.count
        @state = "Receive"
      when "Reset"
        @messageStack = []
        @messageCount = event.count
        @state = "Reset"

  handleReceive: (msg, onComplete) =>
    @messageStack.push(msg)
    if(@messageStack.length == @messageCount)
      deflated = @messageStack.join("")
      data = Kompressor.decompress(deflated)
      @state = "Ready"
      onComplete(data)

  onReceiveChannelStateChange: () =>
    readyState = @channel.readyState
    @logger('Receive channel state is: ' + readyState)
    if(readyState is 'open')
      @state = "Ready"
    return

  onCreateSessionDescriptionError: (error) ->
    @logger('Failed to create session description: ' + error.toString())
    return

  gotDescription: (desc) =>
    @logger('Setting client local description: ' + desc.sdp)
    @connection.setLocalDescription(desc)
    return
