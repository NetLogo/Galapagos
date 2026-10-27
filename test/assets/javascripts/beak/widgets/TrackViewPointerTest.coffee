import assert from 'assert'
import trackViewPointer from '../../../main/beak/widgets/draw/track-view-pointer.js'

describe('trackViewPointer()', () ->

  element  = undefined
  calls    = undefined
  captured = undefined

  fire = (type, { pointerType = 'touch', pointerId = 1, isPrimary = true, x = 50, y = 50 } = {}) ->
    element.fire(type, { pointerType, pointerId, isPrimary, clientX: x, clientY: y })
    return

  beforeEach(() ->
    listeners = {}
    captured  = []
    element   = {
      addEventListener:  (type, f) -> listeners[type] = f
      setPointerCapture: (id) -> captured.push(id)
      fire:              (type, e) -> listeners[type]?(e)
    }
    calls  = []
    record = (name) -> (arg) -> calls.push([name, arg.xPcor, arg.yPcor])
    isIn   = (n) -> 0 <= n <= 100
    trackViewPointer(element, { downHandler: record('down'), moveHandler: record('move'), upHandler: record('up') }
    , (e) -> [{ xPcor: e.clientX, yPcor: e.clientY }, isIn(e.clientX) and isIn(e.clientY)])
  )

  names = () -> calls.map( ([name]) -> name )

  it('reports a tap as one press and one release, and captures the pointer', () ->
    fire('pointerdown')
    fire('pointerup')
    assert.deepEqual(names(), ['down', 'up'])
    assert.deepEqual(captured, [1])
  )

  it('ignores a second finger', () ->
    fire('pointerdown')
    fire('pointerdown', { pointerId: 2, isPrimary: false, x: 80 })
    fire('pointermove', { pointerId: 2, isPrimary: false, x: 90 })
    fire('pointerup',   { pointerId: 2, isPrimary: false, x: 90 })
    fire('pointermove', { x: 60 })
    fire('pointerup',   { x: 60 })
    assert.deepEqual(calls, [['down', 50, 50], ['move', 60, 50], ['up', 60, 50]])
  )

  it('keeps the press while the pointer is outside the view, with no position there', () ->
    fire('pointerdown')
    fire('pointermove',  { x: 150 })
    fire('pointerleave', { x: 150 })
    fire('pointermove',  { x: 60 })
    fire('pointerup',    { x: 60 })
    assert.deepEqual(calls, [['down', 50, 50], ['move', undefined, undefined], ['move', 60, 50], ['up', 60, 50]])
  )

  it('reports a release outside the view at the last position inside it', () ->
    fire('pointerdown', { pointerType: 'mouse' })
    fire('pointermove', { pointerType: 'mouse', x: 70 })
    fire('pointermove', { pointerType: 'mouse', x: 150 })
    fire('pointerup',   { pointerType: 'mouse', x: 150 })
    assert.deepEqual(calls.at(-1), ['up', 70, 50])
  )

  it('ends the press when the browser cancels it', () ->
    fire('pointerdown')
    fire('pointercancel')
    fire('pointerup')
    assert.deepEqual(names(), ['down', 'up'])
  )

  it('reports a mouse hovering, but not a release that began outside the view', () ->
    fire('pointermove', { pointerType: 'mouse', x: 10 })
    fire('pointerup',   { pointerType: 'mouse', x: 10 })
    assert.deepEqual(names(), ['move'])
  )

  contextMenu = (isCancelled) ->
    element.fire('contextmenu', { clientX: 50, clientY: 50, defaultPrevented: isCancelled })
    new Promise((resolve) -> setTimeout(resolve, 0))

  it('ends a mouse press when the browser opens its own menu, and reports the next press', () ->
    fire('pointerdown', { pointerType: 'mouse' })
    await contextMenu(false)
    fire('pointerdown', { pointerType: 'mouse' })
    fire('pointerup',   { pointerType: 'mouse' })
    assert.deepEqual(names(), ['down', 'up', 'down', 'up'])
  )

  it('keeps a mouse press when our menu opens', () ->
    fire('pointerdown', { pointerType: 'mouse' })
    await contextMenu(true)
    assert.deepEqual(names(), ['down'])
    fire('pointerup', { pointerType: 'mouse' })
    assert.deepEqual(names(), ['down', 'up'])
  )

  it('leaves a touch press to the long-press handling', () ->
    fire('pointerdown')
    await contextMenu(false)
    assert.deepEqual(names(), ['down'])
  )

  it('ignores a menu that opens after the release', () ->
    fire('pointerdown', { pointerType: 'mouse' })
    fire('pointerup',   { pointerType: 'mouse' })
    await contextMenu(false)
    assert.deepEqual(names(), ['down', 'up'])
  )

)
