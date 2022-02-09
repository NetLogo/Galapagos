createDebugListener = (events) ->
  debugListener = {}
  events.forEach( (event) ->
    debugListener[event.name] = (args...) ->
      namedArgs = {}
      event.args.forEach( (arg, i) ->
        namedArgs[arg] = args[i]
      )
      console.log(event.name, namedArgs)
  )
  debugListener

export { createDebugListener }
