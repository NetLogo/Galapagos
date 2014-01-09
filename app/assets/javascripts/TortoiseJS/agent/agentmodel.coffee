class window.AgentModel
  constructor: () ->
    @turtles = {}
    @patches = {}
    @links = {}
    @observer = {}
    @world = {}

  update: (modelUpdate) ->
    turtleUpdates = modelUpdate.turtles
    if turtleUpdates
      for turtleId in Object.keys(turtleUpdates)
        if isFinite(turtleId)
          @updateTurtle(turtleId, turtleUpdates[turtleId])
    linkUpdates = modelUpdate.links
    if linkUpdates
      for linkId in Object.keys(linkUpdates)
        @updateLink(linkId, linkUpdates[linkId])
    if modelUpdate.world? and modelUpdate.world[0]?
      # TODO: This is really not okay. The model and the updates should be the
      # same format.
      worldUpdate = modelUpdate.world[0]
      mergeObjectInto(modelUpdate.world[0], @world)
      # TODO: I don't like this either...
      if worldUpdate.worldWidth? and worldUpdate.worldHeight?
        @patches = {}
    patchUpdates = modelUpdate.patches
    if patchUpdates
      for patchId in Object.keys(patchUpdates)
        @updatePatches(patchId, patchUpdates[patchId])
    if modelUpdate.observer? and modelUpdate.observer[0]?
      mergeObjectInto(modelUpdate.observer[0], @observer)
    return

  updateTurtle: (turtleId, varUpdates) ->
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

  updateLink: (linkId, varUpdates) ->
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

  updatePatches: (patchId, varUpdates) ->
    p = @patches[patchId]
    p ?= @patches[patchId] = {}
    mergeObjectInto(varUpdates, p)

  mergeObjectInto = (updatedObject, targetObject) ->
    # Chrome complains it can't inline this function. Changing this to a
    # regular for loop over Object.keys fixes this, but actually makes
    # performance worse.
    for variable, value of updatedObject
      targetObject[variable.toLowerCase()] = value
    return
