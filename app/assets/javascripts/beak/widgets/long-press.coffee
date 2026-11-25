import { dragThresholdFor, isTouchLike } from "./pointer-drag.js"
import { trace } from "./trace-panel.js"

LONG_PRESS_DELAY = 500

LONG_PRESS_SCOPE = [
  '.netlogo-widget-container', '.netlogo-model-title', '.inspection-agent-monitor-view-container', '.async-popup'
].join(', ')

NO_LONG_PRESS = 'input, textarea, select, [contenteditable], .CodeMirror, .netlogo-slider-bar'

DIALOG = '.widget-edit-form-overlay, .netlogo-modal-container, .async-popup'

isInstalled = false

# () => Unit
installLongPress = ->

  if isInstalled
    return

  isInstalled     = true
  press           = undefined
  ownEvent        = undefined
  isMenuFromPress = false

  # From a finger going down until the next press, the only `contextmenu` let through is the one we send.  The
  # browser's own long-press menu (Android sends one, sometimes only on release) is blocked, however it is timed.
  # -Jeremy B November 2026
  isBlockingNativeMenu = false

  # Whether a `click` follows a held press is up to the browser: iOS Safari sends one, Android Chrome and Firefox do
  # not.  So on lift we send our own, unless our menu opened, and eat the browser's if it comes before the next press.
  # -Jeremy B November 2026
  isEatingClick = false

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
      ownEvent.isLongPress = true
      press.hasOpenedMenu  = menuTarget?.dispatchEvent(ownEvent) is false
      ownEvent             = undefined
      detached             = if target.isConnected then '' else ' (target detached, used point)'
      held                 = if press.hasOpenedMenu then 'HeldMenu' else 'HeldNoMenu'
      trace('long-press', "delay ended, sent contextmenu#{detached} → #{held}")
      if press.hasOpenedMenu
        isMenuFromPress = true
        window.getSelection()?.removeAllRanges()
      return

  # (PointerEvent) => Unit
  handleDown =
    (e) ->
      if press?
        trace('long-press', "new pointerdown with press #{press.pointerId} unfinished (fired: #{press.hasFired})")
      if isEatingClick
        trace('long-press', 'EatClick ended by new press')
      stopTimer()
      press                = undefined
      isBlockingNativeMenu = false
      isMenuFromPress      = false
      isEatingClick        = false
      isInScope            = e.target.closest?(LONG_PRESS_SCOPE)? and not e.target.closest(NO_LONG_PRESS)?
      if e.isPrimary and (e.button is 0) and isTouchLike(e) and isInScope
        isBlockingNativeMenu = true
        press = {
          pointerId:     e.pointerId
        , target:        e.target
        , clientX:       e.clientX
        , clientY:       e.clientY
        , threshold:     dragThresholdFor(e.pointerType)
        , hasFired:      false
        , hasOpenedMenu: false
        , timerId:       if e.target.closest(DIALOG)? then undefined else window.setTimeout(fire, LONG_PRESS_DELAY)
        }
        delay = if press.timerId? then '' else ', no delay (in dialog)'
        trace('long-press', "Pressing, native menu blocked, threshold #{press.threshold}px#{delay}")
      return

  # (PointerEvent) => Unit
  handleMove =
    (e) ->
      if press?.timerId? and (e.pointerId is press.pointerId)
        dx = e.clientX - press.clientX
        dy = e.clientY - press.clientY
        if (Math.abs(dx) >= press.threshold) or (Math.abs(dy) >= press.threshold)
          stopTimer()
          trace('long-press', "moved #{Math.round(dx)},#{Math.round(dy)} past threshold, delay stopped")
      return

  # () => Unit
  sendClick =
    ->
      { target, clientX, clientY } = press
      clickTarget = if target.isConnected then target else document.elementFromPoint(clientX, clientY)
      clickTarget?.dispatchEvent(new MouseEvent('click', {
        bubbles:    true
      , cancelable: true
      , view:       window
      , detail:     1
      , clientX
      , clientY
      }))
      return

  # (PointerEvent) => Unit
  handleUp =
    (e) ->
      if press? and (e.pointerId is press.pointerId)
        stopTimer()
        if press.hasFired and (e.type is 'pointerup')
          if not press.hasOpenedMenu
            sendClick()
          isEatingClick = true
          trace('long-press', "#{if press.hasOpenedMenu then 'HeldMenu' else 'HeldNoMenu, sent click'} → EatClick")
        else
          trace('long-press', "#{e.type} → Idle (fired: #{press.hasFired})")
        press = undefined
      return

  # (MouseEvent) => Unit
  handleClick =
    (e) ->
      if isEatingClick and (e.detail > 0)
        isEatingClick = false
        e.preventDefault()
        e.stopImmediatePropagation()
        trace('long-press', 'ate browser click → Idle')
      return

  # (MouseEvent) => Unit
  handleContextMenu =
    (e) ->
      if (e isnt ownEvent) and isBlockingNativeMenu
        e.preventDefault()
        e.stopImmediatePropagation()
        trace('long-press', 'blocked native contextmenu')
      return

  # A long press selects the nearest text, which for the view canvas is in whatever widget sits next to it.  Once our
  # menu opens, nothing is selectable until the next press, since iOS may cancel the pointer as its own gesture starts.
  # -Jeremy B November 2026
  # (Event) => Unit
  handleSelectStart =
    (e) ->
      if isMenuFromPress or (press? and not press.target.contains(e.target))
        e.preventDefault()
        trace('long-press', 'blocked selectstart')
      return

  document.addEventListener('pointerdown'  , handleDown, true)
  document.addEventListener('pointermove'  , handleMove, true)
  document.addEventListener('pointerup'    , handleUp  , true)
  document.addEventListener('pointercancel', handleUp  , true)
  window.addEventListener('contextmenu', handleContextMenu, true)
  window.addEventListener('click', handleClick, true)
  document.addEventListener('selectstart', handleSelectStart, true)

  return

export default installLongPress
