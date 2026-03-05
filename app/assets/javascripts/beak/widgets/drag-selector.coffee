# Makes the specified `ViewController` listen for drags. When a drag (which
# includes a click) begins, the `onBegin` function is executed with a boolean
# argument describing whether the drag is a shift/ctrl drag. Whenever a drag is
# finished, the `onComplete` function is executed with the list of agents within
# the the dragged area as an argument . Returns an unsubscribe function that can be
# used to stop listening; running this function will not run `onComplete`.
# Requires the `world` global variable (of type `World`) to be available.
# (ViewController, RactiveDragSelectionBox, (boolean) -> Unit, (Array[Agent]) -> Unit) -> (Unit) -> Unit
attachDragSelector = (viewController, dragSelectionBox, onBegin, onComplete) ->
  # Creating these variables in this private scope essentially turns them into state that is used by the handler
  # functions below.
  startClientX = undefined # the pixel-based position of where the mouse started dragging; immune to world-wrapping
  startClientY = undefined
  startX = undefined # the patch coordinates of where the mouse started dragging
  startY = undefined
  endX = undefined # the patch coordinates of where the mouse is currently dragging to
  endY = undefined

  # (number, number) -> Array[Agent]
  getAgentsInArea = (endClientX, endClientY) ->
    # The drag never went through valid points.
    if not startX? or not startY? then return []

    ###
    The weirdness of these calculations is intended to account for wrapping.

    The reason I used this strange algorithm is because we can't make any guarantees about whether `startX > endX` or
    `startClientX > endClientX`, etc.

    Explanation of algorithm:

    First focus on the patch coordinate space: the x or y coordinate of the test point is compared (using >=) to both
    the start and end points of the drag, producing two booleans. These booleans differ if the test point is between the
    two boundary points (i.e. greater than one but not greater than the other), and are the same otherwise; therefore
    the XOR of the two determine if the point is between the two boundary points.

    "Being between the two boundary points" is almost equivalent to "being within the selected region" except that we
    want to negate if wrapping has occurred. The variables `xwrap` and `ywrap` determine whether wrapping has occured,
    so use another XOR to negate in the case of wrapping.

    To calculate the values of `xwrap` and `ywrap`: notice that if no wrapping has occurred, both the pair of patch
    coordinate boundary points and the pair of pixel coordinate boundary points agree on the direction the mouse moved
    during the drag. However, if the pixel coord points say that the mouse went one way while the patch coord points say
    that the mouse landed in the opposite direction in-universe, then wrapping must have occurred. Therefore, we use an
    XOR to find whether there is disagreement.
    ###
    xwrap = (endClientX >= startClientX) isnt (endX >= startX)
    ywrap = (endClientY <= startClientY) isnt (endY >= startY)
    checkWithinRegion = (x, y) ->
      # Parentheses inserted to prevent chained comparisons (i.e `a isnt b isnt c` becoming `a isnt b and a isnt c`)
      (xwrap isnt ((x >= startX) isnt (x >= endX))) and (ywrap isnt ((y >= startY) isnt (y >= endY)))

    selectedTurtles = world.turtles().iterator().filter((turtle) -> checkWithinRegion(turtle.xcor, turtle.ycor))
    selectedPatches = world.patches().iterator().filter((patch) -> checkWithinRegion(patch.pxcor, patch.pycor))
    selectedLinks = world.links().iterator().filter((l) -> checkWithinRegion(l.getMidpointX(), l.getMidpointY()))
    selectedTurtles.concat(selectedPatches, selectedLinks)

  updatePosition = (xPcor, yPcor) ->
    # For the start coordinates, set it as soon as we get a valid one, and keep that for the rest of the drag. For the
    # end coordinates, don't update if the drag goes out of world bounds; only keep the last valid coordinate.
    # Update the coordinates individually because their validity is independent (the mouse could be out of bounds but
    # still have an in-bounds x-coordinate, which needs to update as the mouse is moving).
    # This function assumes that the world is a rectangle of valid point surrounded by a sea of invalid points.
    if xPcor?
      startX or= xPcor
      endX = xPcor
    if yPcor?
      startY or= yPcor
      endY = yPcor

  downHandler = ({ clientX, clientY, xPcor, yPcor, event: { ctrlKey, shiftKey } }) ->
    startClientX = clientX
    startClientY = clientY
    startX = undefined # will be updated by updatePosition
    startY = undefined
    dragSelectionBox.beginDrag(clientX, clientY)
    updatePosition(xPcor, yPcor)
    onBegin(ctrlKey or shiftKey)
  moveHandler = ({ clientX, clientY, xPcor, yPcor }) ->
    if dragSelectionBox.checkDragInProgress()
      dragSelectionBox.continueDrag(clientX, clientY)
      updatePosition(xPcor, yPcor)
  upHandler = ({ clientX, clientY }) ->
    dragSelectionBox.endDrag()
    onComplete(getAgentsInArea(clientX, clientY))
  unsubscribe = viewController.registerMouseListeners(downHandler, moveHandler, upHandler)
  unsubscribe

export {
  attachDragSelector
}
