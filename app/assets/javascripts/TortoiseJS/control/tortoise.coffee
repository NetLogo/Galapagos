class Tortoise
  constructor = (@connection, @controller) ->
    @connection.on 'update', (msg)       => @update(JSON.parse(msg.message))
    @connection.on 'js', (msg)           => @runJS(msg.message)
    @connection.on 'model_update', (msg) => @evalJS(msg.message)


  update: (modelUpdate) ->
    if modelUpdate instanceof Array
      @controller.update(update) for update in modelUpdate
    else
      @controller.update(modelUpdate)
    @controller.repaint()

  evalJS: (js) ->
    eval.call(window, js)
    @update(collectUpdates())

  runJS: (js) ->
    (new Function(js)).call(window, js)
    @update(collectUpdates())

  run: (agentType, cmd) ->
    @connection.send({agentType: agentType, cmd: cmd})
