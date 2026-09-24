# type DragInfo = {
#   clientX:  Number  # the pointer's current position
# , clientY:  Number
# , dx:       Number  # how far the pointer has come since the drag began
# , dy:       Number
# , altKey:   Boolean
# , ctrlKey:  Boolean
# , metaKey:  Boolean
# , shiftKey: Boolean
# }
#
# type DragHandlers = {
#   onStart?:  (DragInfo) => Unit  # runs once, when the pointer first moves past `threshold`
# , onMove?:   (DragInfo) => Unit
# , onEnd?:    (DragInfo) => Unit  # runs on pointer-up and on pointer-cancel, but only if the drag ever started
# , threshold?: Number  # defaults to `dragThresholdFor` the pointer's type
# }

# How far the pointer must travel before we call it a drag instead of a click.  Without this, a sloppy click that
# wiggles a pixel would count as a move, and a double-click to edit would be nearly impossible to land.  A fingertip
# wanders much further than a mouse during a tap, so touch needs a far larger allowance.
DRAG_THRESHOLDS = { mouse: 3, pen: 5, touch: 10 }

# (String) => Number
dragThresholdFor = (pointerType) ->
  DRAG_THRESHOLDS[pointerType] ? DRAG_THRESHOLDS.mouse

# Put on the body for the duration of a drag, so dragging over the page doesn't select text everywhere.
DRAGGING_CLASS = 'nlw-pointer-dragging'

# Releasing the pointer fires a `click` on the way out of a drag, which the old drag-and-drop code never did.  That
# click bubbles to whatever is behind the thing being dragged -- for a resize handle, the widget container, which
# deselects on click -- so the handles would disappear the moment you dropped them.  Nothing wants to treat the end of
# a drag as a click, so the next one gets eaten.  The timeout is for the case where no click follows at all, which
# happens when the element the drag began on is re-rendered mid-drag.
# () => Unit
swallowNextClick = ->
  timerId = undefined
  swallow =
    (e) ->
      e.stopPropagation()
      e.preventDefault()
      stopSwallowing()
      return
  stopSwallowing =
    ->
      window.clearTimeout(timerId)
      window.removeEventListener('click', swallow, true)
      return
  window.addEventListener('click', swallow, true)
  timerId = window.setTimeout(stopSwallowing, 0)
  return

# Tracks one pointer from `pointerdown` to `pointerup`, reporting how far it has moved.  The element captures the
# pointer, so the drag keeps working when the pointer leaves it, or leaves the window entirely.
# (Element, PointerEvent, DragHandlers) => Boolean
startPointerDrag = (node, event, { onStart, onMove, onEnd, threshold = dragThresholdFor(event.pointerType) }) ->

  if (event.button isnt 0) or (not event.isPrimary)
    return false

  pointerId  = event.pointerId
  startX     = event.clientX
  startY     = event.clientY
  hasStarted = false
  pending    = undefined
  frameId    = undefined

  toInfo =
    (e) -> {
      clientX:  e.clientX
    , clientY:  e.clientY
    , dx:       e.clientX - startX
    , dy:       e.clientY - startY
    , altKey:   e.altKey
    , ctrlKey:  e.ctrlKey
    , metaKey:  e.metaKey
    , shiftKey: e.shiftKey
    }

  # Pointer moves can arrive several times per frame, and each one costs us a round of Ractive `set`s and a re-render,
  # so only the most recent one is acted on, once per frame.
  flush =
    ->
      frameId = undefined
      if pending?
        info    = pending
        pending = undefined
        onMove?(info)
      return

  schedule =
    (info) ->
      pending = info
      if not frameId?
        frameId = window.requestAnimationFrame(flush)
      return

  handleMove        = undefined
  handleUp          = undefined
  handleContextMenu = undefined

  cleanUp =
    ->
      if frameId?
        window.cancelAnimationFrame(frameId)
        frameId = undefined
      pending = undefined
      node.removeEventListener('pointermove'  , handleMove)
      node.removeEventListener('pointerup'    , handleUp)
      node.removeEventListener('pointercancel', handleUp)
      window.removeEventListener('contextmenu', handleContextMenu, true)
      document.body.classList.remove(DRAGGING_CLASS)
      if node.hasPointerCapture?(pointerId)
        node.releasePointerCapture(pointerId)
      return

  handleMove =
    (e) ->
      if e.pointerId is pointerId
        info = toInfo(e)
        if not hasStarted
          if (Math.abs(info.dx) >= threshold) or (Math.abs(info.dy) >= threshold)
            hasStarted = true
            document.body.classList.add(DRAGGING_CLASS)
            onStart?(info)
        if hasStarted
          schedule(info)
      return

  handleUp =
    (e) ->
      if e.pointerId is pointerId
        lastMove = pending
        wasDrag  = hasStarted
        cleanUp()
        if wasDrag
          if lastMove?
            onMove?(lastMove)
          onEnd?(toInfo(e))
          swallowNextClick()
      return

  handleContextMenu =
    ->
      if not hasStarted
        cleanUp()
      return

  node.setPointerCapture(pointerId)
  node.addEventListener('pointermove'  , handleMove)
  node.addEventListener('pointerup'    , handleUp)
  node.addEventListener('pointercancel', handleUp)
  window.addEventListener('contextmenu', handleContextMenu, true)

  true

export default startPointerDrag
export { dragThresholdFor }
