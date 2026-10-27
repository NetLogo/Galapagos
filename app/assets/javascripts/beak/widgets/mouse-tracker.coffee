import { dragThresholdFor } from "./pointer-drag.js"

class MouseTracker
  x: 0
  y: 0
  down: false
  inside: false
  readCount: 0

  # (Unit) -> Unit
  unsubscribe: ->

  # (number, number) -> Unit
  updateMouseLocation: (xPcor, yPcor) ->
    if not xPcor? or not yPcor?
      # Mouse is outside the world boundaries.
      @inside = false
      # Leave the `x` and `y` properties untouched, so that they report the coordinates the last time the mouse was
      # inside.
    else
      @inside = true
      @x = xPcor
      @y = yPcor
    # Leave the `down` property untouched, since that doesn't care about whether the mouse is outside world
    # boundaries, in parity with NetLogo Desktop behavior. (This might change, and IMO should)

  # (ViewController, (Unit) -> Unit) -> Unit
  constructor: (viewController, onUnreadTouchDrag = (->)) ->
    touchPress = undefined
    trackDistance = (clientX, clientY) ->
      distance = Math.hypot(clientX - touchPress.clientX, clientY - touchPress.clientY)
      touchPress.maxDistance = Math.max(touchPress.maxDistance, distance)
    downHandler = ({ event, clientX, clientY, xPcor, yPcor }) =>
      @down = true
      touchPress =
        if event?.pointerType is 'touch'
          { clientX, clientY, readCount: @readCount, maxDistance: 0 }
        else
          undefined
      @updateMouseLocation(xPcor, yPcor)
    moveHandler = ({ clientX, clientY, xPcor, yPcor }) =>
      if touchPress?
        trackDistance(clientX, clientY)
      @updateMouseLocation(xPcor, yPcor)
    upHandler = ({ event, clientX, clientY } = {}) =>
      if touchPress? and event?.type is 'pointerup' and @readCount is touchPress.readCount
        trackDistance(clientX, clientY)
        if touchPress.maxDistance >= dragThresholdFor('touch')
          onUnreadTouchDrag()
      touchPress = undefined
      @inside = false
      @down = false
    @unsubscribe = viewController.registerMouseListeners(downHandler, moveHandler, upHandler)
    return

export {
  MouseTracker
}
