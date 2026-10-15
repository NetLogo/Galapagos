import assert from 'assert'
import { MouseTracker } from '../../../main/beak/widgets/mouse-tracker.js'

describe('MouseTracker unread touch drag', () ->

  tracker  = undefined
  handlers = undefined
  hints    = undefined

  press = (type, pointerType, x, y = 50) ->
    arg = { event: { type, pointerType }, clientX: x, clientY: y, xPcor: x, yPcor: y }
    switch type
      when 'pointerdown' then handlers.down(arg)
      else                    handlers.up(arg)
    return

  beforeEach(() ->
    hints          = 0
    viewController = {
      registerMouseListeners: (down, move, up) ->
        handlers = { down, move, up }
        (->)
    }
    tracker = new MouseTracker(viewController, (-> hints += 1))
  )

  it('reports a touch drag that the model never read', () ->
    press('pointerdown', 'touch', 50)
    press('pointerup',   'touch', 80)
    assert.equal(hints, 1)
  )

  it('does not report a touch drag when the model read the mouse during it', () ->
    press('pointerdown', 'touch', 50)
    tracker.readCount += 1
    press('pointerup',   'touch', 80)
    assert.equal(hints, 0)
  )

  it('does not report a tap or a long press', () ->
    press('pointerdown', 'touch', 50)
    press('pointerup',   'touch', 53)
    assert.equal(hints, 0)
  )

  it('does not report a mouse drag', () ->
    press('pointerdown', 'mouse', 50)
    press('pointerup',   'mouse', 80)
    assert.equal(hints, 0)
  )

  it('does not report a press cancelled by a second finger', () ->
    press('pointerdown',   'touch', 50)
    press('pointercancel', 'touch', 80)
    assert.equal(hints, 0)
  )

  it('handles a release replayed without an event', () ->
    press('pointerdown', 'touch', 50)
    handlers.up({})
    assert.equal(hints, 0)
    assert.equal(tracker.down, false)
  )

)
