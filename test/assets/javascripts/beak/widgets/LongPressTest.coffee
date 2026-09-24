import assert from 'assert'
import installLongPress from '../../../main/beak/widgets/long-press.js'

describe('installLongPress()', () ->

  container    = undefined
  overlay      = undefined
  input        = undefined
  outside      = undefined
  timers       = []
  menus        = []
  originals    = {}

  recordMenu = (e) -> menus.push(e)

  pointer = (target, type, pointerType, clientX = 100, clientY = 100) ->
    e = new window.Event(type, { bubbles: true, cancelable: true })
    Object.assign(e, { pointerType, clientX, clientY, pointerId: 1, isPrimary: true, button: 0 })
    target.dispatchEvent(e)
    return

  runTimers = () ->
    pending = timers
    timers  = []
    f() for f in pending
    return

  before(() ->
    originals = {
      setTimeout:   window.setTimeout
    , clearTimeout: window.clearTimeout
    , MouseEvent:   global.MouseEvent
    }
    global.MouseEvent = window.MouseEvent
    window.setTimeout = (f) -> timers.push(f); timers.length
    window.clearTimeout = (id) -> timers[id - 1] = (->); return

    document.body.innerHTML = """
      <div class="netlogo-widget-container">
        <div class="editor-overlay"></div>
        <input type="text">
      </div>
      <div class="elsewhere"></div>
    """
    container = document.querySelector('.netlogo-widget-container')
    overlay   = document.querySelector('.editor-overlay')
    input     = document.querySelector('input')
    outside   = document.querySelector('.elsewhere')

    installLongPress()
    document.addEventListener('contextmenu', recordMenu)
  )

  after(() ->
    document.removeEventListener('contextmenu', recordMenu)
    window.setTimeout   = originals.setTimeout
    window.clearTimeout = originals.clearTimeout
    global.MouseEvent   = originals.MouseEvent
    document.body.innerHTML = ''
  )

  beforeEach(() ->
    timers = []
    menus  = []
  )

  afterEach(() ->
    pointer(outside, 'pointerdown', 'mouse')
  )

  it('sends a context menu event to the pressed element when a finger holds still', () ->
    pointer(overlay, 'pointerdown', 'touch')
    runTimers()
    assert.equal(menus.length, 1)
    assert.equal(menus[0].target, overlay)
    assert.equal(menus[0].clientX, 100)
    pointer(overlay, 'pointerup', 'touch')
  )

  it('lets a finger wander under the drag threshold', () ->
    pointer(overlay, 'pointerdown', 'touch')
    pointer(overlay, 'pointermove', 'touch', 109, 100)
    runTimers()
    assert.equal(menus.length, 1)
    pointer(overlay, 'pointerup', 'touch')
  )

  it('gives up once the finger moves far enough to drag', () ->
    pointer(overlay, 'pointerdown', 'touch')
    pointer(overlay, 'pointermove', 'touch', 110, 100)
    runTimers()
    assert.equal(menus.length, 0)
  )

  it('gives up when the finger lifts or the browser cancels the touch', () ->
    pointer(overlay, 'pointerdown', 'touch')
    pointer(overlay, 'pointerup', 'touch')
    runTimers()
    pointer(overlay, 'pointerdown', 'touch')
    pointer(overlay, 'pointercancel', 'touch')
    runTimers()
    assert.equal(menus.length, 0)
  )

  it('leaves the mouse to its own right-click', () ->
    pointer(overlay, 'pointerdown', 'mouse')
    runTimers()
    assert.equal(menus.length, 0)
  )

  it('ignores presses outside the interface and on text fields', () ->
    pointer(outside, 'pointerdown', 'touch')
    runTimers()
    pointer(input, 'pointerdown', 'touch')
    runTimers()
    assert.equal(menus.length, 0)
  )

  nativeMenu = (target) ->
    target.dispatchEvent(new window.MouseEvent('contextmenu', { bubbles: true, cancelable: true }))
    return

  it("blocks the browser's own menu for the whole press, even after the finger moves", () ->
    pointer(overlay, 'pointerdown', 'touch')
    nativeMenu(overlay)
    pointer(overlay, 'pointermove', 'touch', 150, 100)
    nativeMenu(overlay)
    pointer(overlay, 'pointerup', 'touch', 150, 100)
    nativeMenu(overlay)
    assert.equal(menus.length, 0)
  )

  it("still sends its own menu after blocking the browser's", () ->
    pointer(overlay, 'pointerdown', 'touch')
    nativeMenu(overlay)
    runTimers()
    assert.equal(menus.length, 1)
    pointer(overlay, 'pointerup', 'touch')
  )

  it('leaves a mouse right-click alone right after a touch', () ->
    pointer(overlay, 'pointerdown', 'touch')
    pointer(overlay, 'pointerup', 'touch')
    pointer(overlay, 'pointerdown', 'mouse')
    nativeMenu(overlay)
    assert.equal(menus.length, 1)
  )

  it('eats the click that follows the lifted finger', () ->
    clicks = 0
    countClick = () -> clicks += 1
    container.addEventListener('click', countClick)
    pointer(overlay, 'pointerdown', 'touch')
    runTimers()
    pointer(overlay, 'pointerup', 'touch')
    overlay.dispatchEvent(new window.MouseEvent('click', { bubbles: true }))
    container.removeEventListener('click', countClick)
    assert.equal(clicks, 0)
  )

)
