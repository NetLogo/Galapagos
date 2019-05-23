# type ViewState = { model: AgentModel, fontSize: Number, drawingLayerData: String, world: Object[Any] }

class window.HubNetWeb

  # (String, SessionLite)
  constructor: (elementID, session) ->

    @ractive =
      new Ractive({
        el:         "##{elementID}"
      , template:   @template
      , components: { connectionManager: RactiveConnectionManager }
      , data:       -> { connected: false }
      })

    viewController = session.widgetController.viewController

    ioSignalingUrl = 'http://localhost:3000'
    clients        = @ractive.findComponent('connectionManager')

    logger = (msg) -> clients.appendToLog(msg)

    @ractive.on('*.server-connect',
      =>

        serverSpy =
          (updates) ->
            server.broadcast(updates)
            return

        session.widgetController.updateSpies.push(serverSpy)

        server = new Server(ioSignalingUrl, logger, (=> @getViewState(viewController)))
        server.connect()

        @ractive.set(   'server', server)
        @ractive.set('connected',   true)

        return

    )

    @ractive.on('*.client-connect',
      =>

        notifyClientView     = (data) -> viewController.update(data)
        resetClientViewState = (viewState) => @resetClientViewState(viewController, viewState)
        notifyDisconnect     = => @ractive.set('connected', false)

        client = new Client(ioSignalingUrl, logger, notifyClientView, resetClientViewState, notifyDisconnect)
        client.connect()
        @ractive.set(   'client', client)
        @ractive.set('connected',   true)

        @ractive.fire('resize-view')
        @ractive.fire('redraw-view')

        return

    )

    @ractive.on('*.disconnect',
      =>
        @ractive.set('connected', false)
        @ractive.get('server')?.close()
        @ractive.get('client')?.disconnect()
        return
    )

  # (ViewController) => ViewState
  getViewState: (viewController) ->

    model            = viewController.model
    fontSize         = viewController.view.fontSize
    drawingLayerData = viewController.drawingLayer.canvas.toDataURL('image/png', 1)

    # We actually need to clone the world to a new object, since we also have to clone the world's properties
    # Some aren't plain fields, they don't get copied over automatically in JSON.stringify() or the like
    # --JMB (~3/5/2018)
    world = {}
    for propName in Object.getOwnPropertyNames(model.world)
      world[propName] = model.world[propName]

    { model, fontSize, drawingLayerData, world }

  # (ViewController, AgentModel) => Unit
  resetClientViewState: (viewController, newViewState) ->

    model = viewController.model
    ['turtles', 'patches', 'links', 'observer', 'drawingEvents'].forEach((x) -> model[x] = newViewState.model[x])

    for propName in Object.getOwnPropertyNames(newViewState.world)
      model.world[propName] = newViewState.world[propName]

    viewController.view.fontSize = newViewState.fontSize

    viewController.drawingLayer.clearDrawing()
    drawingImage = new Image()
    drawingImage.onload =
      ->
        viewController.drawingLayer.ctx.drawImage(drawingImage, 0, 0)
        viewController.repaint()
        return
    drawingImage.src = newViewState.drawingLayerData

    return

  template:
    """
      <div>Hello, HubNet Web!</div>
      <connectionManager connected='{{ connected }}' />
    """
