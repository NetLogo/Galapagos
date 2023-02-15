createDebugListener = (events) ->
  debugListener = {}
  events.forEach( (event) ->
    debugListener[event.name] = (commonArgs, eventArgs) ->
      console.debug(event.name, commonArgs, eventArgs)
  )

  debugListener

export { createDebugListener }
