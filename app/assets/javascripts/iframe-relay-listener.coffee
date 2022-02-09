postMessage = (event, args) ->
  window.parent.postMessage({
    type:  'nlw-notification'
  , event: event
  , args:  args
  }, '*')
  return

createIframeRelayListener = (eventsString, fallbackEvents) ->
  events = if eventsString.trim() isnt ''
    eventsString.split(',').map( (event) -> event.trim() )
  else
    fallbackEvents

  listener = {}
  events.forEach( (event) ->
    listener[event] = (args...) -> postMessage(event, args)
  )

  listener

export { createIframeRelayListener }
