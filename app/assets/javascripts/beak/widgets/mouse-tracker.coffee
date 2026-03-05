class MouseTracker
  x: 0
  y: 0
  down: false
  inside: false

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

  # (ViewController) -> Unit
  constructor: (viewController) ->
    downHandler = ({ xPcor, yPcor }) =>
      @down = true
      @updateMouseLocation(xPcor, yPcor)
    moveHandler = ({ xPcor, yPcor }) =>
      @updateMouseLocation(xPcor, yPcor)
    upHandler = =>
      @inside = false
      @down = false
    @unsubscribe = viewController.registerMouseListeners(downHandler, moveHandler, upHandler)
    return

export {
  MouseTracker
}
