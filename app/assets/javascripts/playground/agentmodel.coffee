class window.AgentModel
  constructor: () ->
    @turtles = {}
    @patches = {}
    @links = {}
    @observer = {}
    @world = {}

  update: (modelUpdate) ->
    for turtleId, varUpdates of modelUpdate.turtles
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
      p = @patches[patchId]
      if not p?
        p = @patches[patchId] = {}
      mergeObjectInto(varUpdates, p)
    mergeObjectInto(modelUpdate.observer, @observer)
    mergeObjectInto(modelUpdate.world, @world)
    return

mergeObjectInto = (updatedObject, targetObject) ->
  for variable, value of updatedObject
    targetObject[variable] = value
