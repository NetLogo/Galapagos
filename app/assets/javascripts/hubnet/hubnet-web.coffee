class window.HubNetWeb
  constructor: (elementId, workspace, session) ->
    @ractive = ractive = new Ractive({
        el:         "##{elementId}"
      , template:   @template
      , components: { connectionManager: RactiveConnectionManager }
      , data: () -> {
        connected: false
      }
    })

    viewController = session.widgetController.viewController

    ioSignalingUrl = 'http://localhost:3000'
    clients = ractive.findComponent('connectionManager')
    logger = (msg) ->
      clients.appendToLog(msg)
      return

    gvs = @getViewState
    ractive.on('*.server-connect', ->
      ractive.set('connected', true)
      getViewState = () ->
        gvs(viewController)
      server = new Server(ioSignalingUrl, logger, getViewState)
      serverSpy = (updates) ->
        server.broadcast(updates)
        return
      session.widgetController.updateSpies.push(serverSpy)
      server.connect()
      ractive.set('server', server)
      return
    )

    rcvs = @resetClientViewState
    ractive.on('*.client-connect', ->
      ractive.set('connected', true)
      notifyClientView = (data) -> viewController.update(data)
      resetClientViewState = (viewState) ->
        rcvs(viewController, viewState)
        return
      notifyDisconnect = () ->
        ractive.set('connected', false)
        return
      client = new Client(ioSignalingUrl, logger, notifyClientView, resetClientViewState, notifyDisconnect)
      client.connect()
      ractive.fire('resize-view')
      ractive.fire('redraw-view')
      ractive.set('client', client)
      return
    )

    ractive.on('*.disconnect', ->
      ractive.set('connected', false)
      ractive.get('server')?.close()
      ractive.get('client')?.disconnect()
      return
    )

  getViewState: (viewController) ->
    model = viewController.model
    world = { }
    # We actually need to clone the world to a new object, since we also have to clone the world's properties
    # Some aren't plain fields, they don't get copied over automatically in JSON.stringify() or the like
    for propName in Object.getOwnPropertyNames(model.world)
      world[propName] = model.world[propName]
    fontSize = viewController.view.fontSize
    drawingLayerData = viewController.drawingLayer.canvas.toDataURL('image/png', 1)
    { model, world, fontSize, drawingLayerData }

  resetClientViewState: (viewController, newViewState) ->
    # model
    model = viewController.model
    for propName in [ 'turtles', 'patches', 'links', 'observer', 'drawingEvents' ]
      model[propName] = newViewState.model[propName]
    # world
    for propName in Object.getOwnPropertyNames(newViewState.world)
      model.world[propName] = newViewState.world[propName]
    # fontSize
    viewController.view.fontSize = newViewState.fontSize
    # drawingLayerData
    viewController.drawingLayer.clearDrawing()
    drawingImage = new Image()
    drawingImage.onload = () ->
      viewController.drawingLayer.ctx.drawImage(drawingImage, 0, 0)
      viewController.repaint()
      return
    drawingImage.src = newViewState.drawingLayerData
    return

  template: """
    <div>Hello, HubNet Web!</div>
    <connectionManager connected='{{ connected }}' />
  """
