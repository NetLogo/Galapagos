import { createNamedArgs } from "./listener-events.js"

postMessage = (event, commonArgs, eventArgs) ->
  window.parent.postMessage({
    type: 'nlw-notification'
  , event
  , commonArgs
  , eventArgs
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
    listener[event.name] = (commonArgs, eventArgs) ->
      postMessage(event.name, commonArgs, eventArgs)
  )

  listener

export { createIframeRelayListener }
