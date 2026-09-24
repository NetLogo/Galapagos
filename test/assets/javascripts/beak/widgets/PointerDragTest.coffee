import assert from 'assert'
import startPointerDrag, { dragThresholdFor } from '../../../main/beak/widgets/pointer-drag.js'

fakeNode = () ->
  listeners = {}
  {
    setPointerCapture:     () ->
    hasPointerCapture:     () -> false
    releasePointerCapture: () ->
    addEventListener:      (type, f) -> listeners[type] = f
    removeEventListener:   (type) -> delete listeners[type]
    fire:                  (type, e) -> listeners[type]?(e)
  }

pointer = (pointerType, clientX, clientY) ->
  { pointerType, clientX, clientY, pointerId: 1, button: 0, isPrimary: true }

describe('dragThresholdFor()', () ->

  it('gives a touch the largest allowance, then a pen, then a mouse', () ->
    assert.equal(dragThresholdFor('mouse'), 3)
    assert.equal(dragThresholdFor('pen'),   5)
    assert.equal(dragThresholdFor('touch'), 10)
  )

  it('treats an unknown pointer type as a mouse', () ->
    assert.equal(dragThresholdFor(''),        3)
    assert.equal(dragThresholdFor(undefined), 3)
  )

)

describe('startPointerDrag()', () ->

  originalRAF = undefined

  beforeEach(() ->
    originalRAF = window.requestAnimationFrame
    window.requestAnimationFrame = () -> 1
    window.cancelAnimationFrame  = () ->
  )

  afterEach(() ->
    window.requestAnimationFrame = originalRAF
  )

  startsAfter = (pointerType, distance, options = {}, beforeMove = (->)) ->
    node    = fakeNode()
    started = false
    startPointerDrag(node, pointer(pointerType, 100, 100), { options..., onStart: () -> started = true })
    beforeMove()
    node.fire('pointermove', pointer(pointerType, 100 + distance, 100))
    node.fire('pointerup',   pointer(pointerType, 100 + distance, 100))
    started

  it('starts a mouse drag after 3 pixels', () ->
    assert.equal(startsAfter('mouse', 2), false)
    assert.equal(startsAfter('mouse', 3), true)
  )

  it('lets a finger wander 9 pixels during a tap', () ->
    assert.equal(startsAfter('touch', 9),  false)
    assert.equal(startsAfter('touch', 10), true)
  )

  it('uses an explicit threshold over the pointer default', () ->
    assert.equal(startsAfter('touch', 1, { threshold: 0 }), true)
  )

  it('gives up on the drag when a context menu opens first', () ->
    openMenu = () -> window.dispatchEvent(new window.Event('contextmenu'))
    assert.equal(startsAfter('touch', 20, {}, openMenu), false)
  )

)
