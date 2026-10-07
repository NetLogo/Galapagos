# (Element, MouseHandlers, (PointerEvent) => [MouseHandlerArg, Boolean]) => Unit
# where MouseHandlers and MouseHandlerArg are as described on `ViewController`, and the Boolean says whether the pointer
# is inside the element
trackViewPointer = (element, { downHandler, moveHandler, upHandler }, toHandlerArg) ->

  activePointerId = undefined
  lastInside      = undefined

  # (PointerEvent) => Unit
  endPress =
    (e) ->
      if e.pointerId is activePointerId
        activePointerId = undefined
        [arg, isInside] = toHandlerArg(e)
        upHandler(if isInside then arg else { ...arg, xPcor: lastInside.xPcor, yPcor: lastInside.yPcor })
      return

  element.addEventListener('pointerdown', (e) ->
    if e.isPrimary and not activePointerId?
      activePointerId = e.pointerId
      element.setPointerCapture(e.pointerId)
      [lastInside] = toHandlerArg(e)
      downHandler(lastInside)
    return
  )

  # Outside the view, the patch coordinates would wrap around to the far side of a wrapping world, so report none.
  element.addEventListener('pointermove', (e) ->
    if e.isPrimary
      [arg, isInside] = toHandlerArg(e)
      if isInside
        lastInside = arg
        moveHandler(arg)
      else if e.pointerId is activePointerId
        moveHandler({ ...arg, xPcor: undefined, yPcor: undefined })
    return
  )

  element.addEventListener('pointerup'    , endPress)
  element.addEventListener('pointercancel', endPress)

  return

export default trackViewPointer
