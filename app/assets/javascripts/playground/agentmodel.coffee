class window.AgentModel
  constructor: () ->
    @turtles = {}
    @patches = []
    @links = {}
    @observer = {}
    @world = {}

  update: (modelUpdate) ->
    for turtleId, varUpdates of modelUpdate.turtles
      t = @turtles[turtleId]
      if not t?
        t = {}
        @turtles[turtleId] = t
      mergeObjectInto(varUpdates, t)
    for patchId, varUpdates of modelUpdate.patches
      p = @patches[patchId]
      mergeObjectInto(varUpdates, p)
    mergeObjectInto(modelUpdate.observer, @observer)
    mergeObjectInto(modelUpdate.world, @world)

mergeObjectInto = (updatedObject, targetObject) ->
  for variable, value of updatedObject
    targetObject[variable] = value
