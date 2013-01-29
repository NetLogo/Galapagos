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
            shape: window.shapes.default,
            color: 'hsl('+(360*Math.random())+',100%,50%)'
          }
      mergeObjectInto(varUpdates, t)
    for patchId, varUpdates of modelUpdate.patches
      anyUpdates = true
      p = @patches[patchId]
      p ?= @patches[patchId] = {}
      mergeObjectInto(varUpdates, p)
    mergeObjectInto(modelUpdate.observer, @observer)
    mergeObjectInto(modelUpdate.world, @world)
    anyUpdates

  mergeObjectInto = (updatedObject, targetObject) ->
    for variable, value of updatedObject
      targetObject[variable.toLowerCase()] = value
    return
