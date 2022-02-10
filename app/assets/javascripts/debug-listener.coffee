import { createNamedArgs } from "./listener-events.js"

createDebugListener = (events) ->
  debugListener = {}
  events.forEach( (event) ->
    debugListener[event.name] = (args...) ->
      namedArgs = createNamedArgs(event.args, args)
      console.log(event.name, namedArgs)
  )

  debugListener

export { createDebugListener }
