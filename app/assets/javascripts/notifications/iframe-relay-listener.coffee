import { createNamedArgs } from "./listener-events.js"

postMessage = (event, commonArgs, eventArgs) ->
  window.parent.postMessage({
    type: 'nlw-notification'
  , event
  , commonArgs
  , eventArgs
  }, '*')
  return

postTaggedMessage = (tag, event, commonArgs, eventArgs) ->
  window.parent.postMessage({
    type: 'nlw-notification'
  , tag
  , event
  , commonArgs
  , eventArgs
  }, '*')
  return

createIframeRelayListener = (allEvents, eventsString, tag) ->
  events = if eventsString.trim() isnt ''
    eventNames = eventsString.split(',').map( (event) -> event.trim() )
    allEvents.filter( (event) -> eventNames.includes(event.name) )
  else
    allEvents

  post = if tag?
    (en, cas, eas) -> postTaggedMessage(tag, en, cas, eas)
  else
    postMessage

  listener = {}
  events.forEach( (event) ->
    listener[event.name] = (commonArgs, eventArgs) ->
      post(event.name, commonArgs, eventArgs)
  )

  listener

export { createIframeRelayListener }
