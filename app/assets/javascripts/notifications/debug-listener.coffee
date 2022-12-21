import { createNamedArgs } from "./listener-events.js"

createDebugListener = (events) ->
  debugListener = {}
  events.forEach( (event) ->
    debugListener[event.name] = (commonArgs, eventArgs) ->
      console.log(event.name, commonArgs, eventArgs)
  )

  debugListener

export { createDebugListener }
