class window.Client

  # (String, (String) => Unit, (Array[Update]) => Unit, (ViewController, AgentModel) => Unit, () => Unit)
  constructor: (@ioSignalingUrl, @logger, @notifyClientView, @resetClientViewState, @notifyDisconnect) ->

    @sendToServer =
      (type, data = {}) =>
        @logger('Received message from server while not connected as client?')
        @logger(data)
        return

    @state = "Disconnected"

  # () => Unit
  connect: ->

    @signalingSocket = io(@ioSignalingUrl)

    @sendToServer =
      (type, data = {}) =>
        message = { clientID: @signalingSocket.id, data, type }
        @signalingSocket.emit('to-server', message)
        return

    @signalingSocket.on('to-client', @handleServerMessage)

    # RTC BEGIN
    @logger('Creating RTC data channel connection...')
    @connection = new RTCPeerConnection({ offerToReceiveAudio: false })
    @logger('Created client connection.')

    @connection.onicecandidate =
      ({ candidate }) =>
        @logger('ICE callback on the client.')
        if candidate?
          @sendToServer('client-ice-candidate', { candidate })
        return

    @channel = @connection.createDataChannel('sendDataChannel', null)

    @channel.onopen =
      =>
        readyState = @channel.readyState
        @logger("Receive channel state is: #{readyState}")
        if readyState is 'open'
          @state = "Ready"
        return

    @channel.onmessage =
      (event) =>
        @logger('Message received on client.')
        if @channel?.readyState is 'open'
          switch @state
            when 'Ready'   then @handleInitMessage(JSON.parse(event.data))
            when 'Receive' then @handleReceive(event.data, @notifyClientView)
            when 'Reset'   then @handleReceive(event.data, @resetClientViewState)
        else
          @logger('Received message while not open... weird.')
        return

    makeOffer =
      =>
        @sendToServer('client-offer', { desc: @connection.localDescription })
        return

    @connection.createOffer().then(@gotDescription, @onCreateSessionDescriptionError).then(makeOffer)
    # RTC END

    @logger('Signaling complete.')

    return

  # () => Unit
  disconnect: ->

    if @channel? and @channel.readyState is 'open'
      @messageStack = ''
      @logger('Closing data channels')
      @channel.close()
      @logger("Closed data channel with label: #{@channel.label}")
      @channel = null

    if @connection?
      @connection.close()
      @logger('Closed connection')
      @connection = null

    @sendToServer('client-disconnect')

    @signalingSocket.close()
    @signalingSocket = null
    @logger('Closed signalling socket')
    @logger('Completed disconnecting.')

    return

  # (String) => Unit
  handleServerMessage: ({ data, type }) =>
    switch type
      when 'client-offer-response'
        @logger('Setting client remote description from server')
        @connection.setRemoteDescription(data.desc)
      when 'server-ice-candidate'
        @connection.addIceCandidate(data.candidate)
      when 'server-close'
        @logger('Apparently the server is rudely closing down; disconnecting.')
        @disconnect()
        @notifyDisconnect()
    return

  # (InitMessage) => Unit
  handleInitMessage: ({ count, type }) ->
    switch type
      when "DataSend"
        @messageStack = []
        @messageCount = count
        @state        = "Receive"
      when "Reset"
        @messageStack = []
        @messageCount = count
        @state        = "Reset"
    return

  # (String, (Object[Any]) => Unit) => Unit
  handleReceive: (msg, onComplete) ->
    @messageStack.push(msg)
    if @messageStack.length is @messageCount
      @state = "Ready"
      onComplete(Kompressor.decompress(@messageStack.join("")))
    return

  # (Error) => Unit
  onCreateSessionDescriptionError: (error) =>
    @logger("Failed to create session description: #{error.toString()}")
    return

  # (RTCSessionDescription) => Unit
  gotDescription: (desc) =>
    @logger("Setting client local description: #{desc.sdp}")
    @connection.setLocalDescription(desc)
    return
