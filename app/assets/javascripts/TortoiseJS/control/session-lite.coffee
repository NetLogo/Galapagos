class window.SessionLite

  @controller = undefined

  constructor: (container) ->
    # Remove the canvas if it already exists (i.e. Standalone Tortoise)
    existingCanvas = container.querySelector("#netlogo-canvas")
    if existingCanvas?
      container.removeChild(existingCanvas)
    @controller = new AgentStreamController(container)

  update: (modelUpdate) ->
    if modelUpdate instanceof Array
      @controller.update(update) for update in modelUpdate
    else
      @controller.update(modelUpdate)
    @controller.repaint()

