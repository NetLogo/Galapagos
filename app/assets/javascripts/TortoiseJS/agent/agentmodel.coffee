class window.AgentModel
  constructor: () ->
    @turtles = {}
    @patches = {}
    @links = {}
    @observer = {}
    @world = {}

  update: (modelUpdate) -> # boolean
    anyUpdates = false
    for turtleId, varUpdates of modelUpdate.turtles
      anyUpdates = true
      if varUpdates == null or varUpdates['WHO'] == -1
        delete @turtles[turtleId]
      else
        t = @turtles[turtleId]
        if not t?
          t = @turtles[turtleId] = {
            heading: 360*Math.random(),
            xcor: 0,
            ycor: 0,
            shape: 'default',
            color: 'hsl('+(360*Math.random())+',100%,50%)'
          }
        mergeObjectInto(varUpdates, t)
    for linkId, varUpdates of modelUpdate.links
      anyUpdates = true
      if varUpdates == null
        delete @links[linkId]
      else
        l = @links[linkId]
        if not l?
          l = @links[linkId] = {
            shape: 'default',
            color: 5
          }
        mergeObjectInto(varUpdates, l)
    if modelUpdate.world? and modelUpdate.world[0]?
      # TODO: This is really not okay. The model and the updates should be the
      # same format.
      worldUpdate = modelUpdate.world[0]
      mergeObjectInto(modelUpdate.world[0], @world)
      # TODO: I don't like this either...
      if worldUpdate.worldWidth? and worldUpdate.worldHeight?
        @patches = {}
    for patchId, varUpdates of modelUpdate.patches
      anyUpdates = true
      p = @patches[patchId]
      p ?= @patches[patchId] = {}
      mergeObjectInto(varUpdates, p)
    mergeObjectInto(modelUpdate.observer, @observer)
    anyUpdates

  mergeObjectInto = (updatedObject, targetObject) ->
    for variable, value of updatedObject
      targetObject[variable.toLowerCase()] = value
    return
