class window.SessionLite

  @controller = undefined

  constructor: (@container) ->
    @controller = new AgentStreamController(container)

  update: (modelUpdate) ->
    if modelUpdate instanceof Array
      @controller.update(update) for update in modelUpdate
    else
      @controller.update(modelUpdate)
    @controller.repaint()

