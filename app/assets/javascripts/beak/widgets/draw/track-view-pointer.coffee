# (Element, MouseHandlers, (PointerEvent) => [MouseHandlerArg, Boolean]) => Unit
trackViewPointer = (element, { downHandler, moveHandler, upHandler }, toHandlerArg) ->

  activePointerId   = undefined
  activePointerType = undefined
  lastInside        = undefined

  # (MouseEvent) => Unit
  release =
    (e) ->
      activePointerId = undefined
      [arg, isInside] = toHandlerArg(e)
      upHandler(if isInside then arg else { ...arg, xPcor: lastInside.xPcor, yPcor: lastInside.yPcor })
      return

  # (PointerEvent) => Unit
  endPress =
    (e) ->
      if e.pointerId is activePointerId
        release(e)
      return

  element.addEventListener('pointerdown', (e) ->
    if e.isPrimary and not activePointerId?
      activePointerId   = e.pointerId
      activePointerType = e.pointerType
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

  # On macOS and Linux, the browser's own menu opens on mousedown and takes the release, so no `pointerup` comes.  Our
  # menu cancels the event further up the page, so wait until it has finished to see whether the browser's will open.  -Jeremy B October 2026
  element.addEventListener('contextmenu', (e) ->
    if activePointerId? and activePointerType is 'mouse'
      setTimeout((->
        if activePointerId? and not e.defaultPrevented
          release(e)
        return
      ), 0)
    return
  )

  return

export default trackViewPointer
