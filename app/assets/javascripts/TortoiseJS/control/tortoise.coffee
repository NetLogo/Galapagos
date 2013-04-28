window.initSession = (socketURL, container) ->
  controller = new AgentStreamController(container)
  connection = connect(socketURL)
  new TortoiseSession(connection, controller)

class TortoiseSession
  constructor: (@connection, @controller) ->
    @connection.on 'update', (msg)       => @update(JSON.parse(msg.message))
    @connection.on 'js', (msg)           => @runJSCommand(msg.message)
    @connection.on 'model_update', (msg) => @evalJSModel(msg.message)

  update: (modelUpdate) ->
    if modelUpdate instanceof Array
      @controller.update(update) for update in modelUpdate
    else
      @controller.update(modelUpdate)
    @controller.repaint()

  evalJSModel: (js) ->
    eval.call(window, js)
    @update(collectUpdates())

  runJSCommand: (js) ->
    (new Function(js)).call(window, js)
    @update(collectUpdates())

  run: (agentType, cmd) ->
    @connection.send({agentType: agentType, cmd: cmd})
