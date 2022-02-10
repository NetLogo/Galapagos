import { createNamedArgs } from "./listener-events.js"

postMessage = (event, args) ->
  window.parent.postMessage({
    type:  'nlw-notification'
  , event: event
  , args:  args
  }, '*')
  return

createIframeRelayListener = (allEvents, eventsString) ->
  events = if eventsString.trim() isnt ''
    eventNames = eventsString.split(',').map( (event) -> event.trim() )
    allEvents.filter( (event) -> eventNames.includes(event.name) )
  else
    allEvents

  listener = {}
  events.forEach( (event) ->
    listener[event.name] = (args...) ->
      namedArgs = createNamedArgs(event.args, args)
      postMessage(event.name, namedArgs)
  )

  listener

export { createIframeRelayListener }
