createDebugListener = (events) ->
  debugListener = {}
  events.forEach( (eventName) ->
    debugListener[eventName] = (args...) ->
      console.log(eventName, args)
  )
  debugListener

export { createDebugListener }
