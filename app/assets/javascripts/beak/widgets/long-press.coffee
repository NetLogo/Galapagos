import { dragThresholdFor, swallowNextClick } from "./pointer-drag.js"

LONG_PRESS_DELAY = 500

# While a finger is down, and for a moment after it lifts, the only `contextmenu` let through is the one we send.  The
# browser's own long-press menu (Android sends one, sometimes only on release) is blocked, however it is timed.
NATIVE_MENU_GRACE = 300

LONG_PRESS_SCOPE = '.netlogo-widget-container, .netlogo-model-title, .inspection-agent-monitor-view-container'

EDITABLE = 'input, textarea, select, [contenteditable], .CodeMirror'

isInstalled = false

# () => Unit
installLongPress = ->

  if isInstalled
    return

  isInstalled   = true
  press         = undefined
  ownEvent      = undefined
  suppressUntil = 0

  # () => Unit
  stopTimer =
    ->
      if press?.timerId?
        window.clearTimeout(press.timerId)
        press.timerId = undefined
      return

  # () => Unit
  fire =
    ->
      { target, clientX, clientY } = press
      press.timerId  = undefined
      press.hasFired = true
      menuTarget     = if target.isConnected then target else document.elementFromPoint(clientX, clientY)
      ownEvent       = new MouseEvent('contextmenu', {
        bubbles:    true
      , cancelable: true
      , view:       window
      , button:     2
      , buttons:    2
      , clientX
      , clientY
      })
      menuTarget?.dispatchEvent(ownEvent)
      ownEvent = undefined
      return

  # (PointerEvent) => Unit
  handleDown =
    (e) ->
      stopTimer()
      press         = undefined
      suppressUntil = 0
      isTouchLike   = (e.pointerType is 'touch') or (e.pointerType is 'pen')
      isInScope     = e.target.closest?(LONG_PRESS_SCOPE)? and not e.target.closest(EDITABLE)?
      if e.isPrimary and (e.button is 0) and isTouchLike and isInScope
        suppressUntil = Infinity
        press = {
          pointerId: e.pointerId
        , target:    e.target
        , clientX:   e.clientX
        , clientY:   e.clientY
        , threshold: dragThresholdFor(e.pointerType)
        , hasFired:  false
        , timerId:   window.setTimeout(fire, LONG_PRESS_DELAY)
        }
      return

  # (PointerEvent) => Unit
  handleMove =
    (e) ->
      if press?.timerId? and (e.pointerId is press.pointerId)
        dx = e.clientX - press.clientX
        dy = e.clientY - press.clientY
        if (Math.abs(dx) >= press.threshold) or (Math.abs(dy) >= press.threshold)
          stopTimer()
      return

  # (PointerEvent) => Unit
  handleUp =
    (e) ->
      if press? and (e.pointerId is press.pointerId)
        stopTimer()
        if press.hasFired
          swallowNextClick()
        suppressUntil = Date.now() + NATIVE_MENU_GRACE
        press         = undefined
      return

  # (MouseEvent) => Unit
  handleContextMenu =
    (e) ->
      if (e isnt ownEvent) and (Date.now() < suppressUntil)
        e.preventDefault()
        e.stopImmediatePropagation()
      return

  document.addEventListener('pointerdown'  , handleDown, true)
  document.addEventListener('pointermove'  , handleMove, true)
  document.addEventListener('pointerup'    , handleUp  , true)
  document.addEventListener('pointercancel', handleUp  , true)
  window.addEventListener('contextmenu', handleContextMenu, true)

  return

export default installLongPress
