
import { isMac, isToggleKeydownEvent } from "./utils.js"

# (HTMLElement, (Object) => Void) => Void
ractiveAccessibleClickEvent = (node, fire) ->
  clickHandler = (event) ->
    fire({ node: node, original: event })

  keydownHandler = (event) ->
    if isToggleKeydownEvent(event)
      event.preventDefault()
      fire({ node: node, original: event })

  node.addEventListener('click', clickHandler, false)
  node.addEventListener('keydown', keydownHandler, false)

  return {
    teardown: ->
      node.removeEventListener('click', clickHandler, false)
      node.removeEventListener('keydown', keydownHandler, false)
  }

# (HTMLElement, (Object) => Void) => Void
ractiveCopyEvent = (node, fire) ->
  keydownHandler = (event) ->
    modKey   = if isMac then event.metaKey else event.ctrlKey
    copyKey  = event.key is 'c'
    matchKey = modKey and copyKey

    if matchKey
      fire({ node: node, original: event })

  node.addEventListener('keydown', keydownHandler, false)

  return {
    teardown: ->
      node.removeEventListener('keydown', keydownHandler, false)
  }

# (HTMLElement, (Object) => Void) => Void
ractivePasteEvent = (node, fire) ->
  keydownHandler = (event) ->
    modKey    = if isMac then event.metaKey else event.ctrlKey
    pasteKey  = event.key is 'v'
    matchKey  = modKey and pasteKey

    if matchKey
      fire({ node: node, original: event })

  node.addEventListener('keydown', keydownHandler, false)

  return {
    teardown: ->
      node.removeEventListener('keydown', keydownHandler, false)
  }


export {
  ractiveAccessibleClickEvent,
  ractiveCopyEvent,
  ractivePasteEvent
}
