import assert from 'assert'
import { autoSizedDims } from '../../../main/beak/widgets/auto-size.js'

describe('autoSizedDims()', () ->

  size = (width, height) -> { width, height }

  run = (overrides) ->
    autoSizedDims({
      current:         size(100, 40)
    , preferred:       size(null, null)
    , preferredBefore: null
    , isNew:           false
    , canResize:       { width: true, height: true }
    , minimums:        size(35, 30)
    , overrides...
    })

  describe('for a new widget', () ->

    it('grows to the preferred size, rounded up to the grid', () ->
      assert.deepEqual(run({ isNew: true, preferred: size(132, 51) }), size(135, 55))
    )

    it('shrinks to the preferred size too', () ->
      assert.deepEqual(run({ isNew: true, preferred: size(55, null) }), size(55, 40))
    )

    it('never goes below the minimum size', () ->
      assert.deepEqual(run({ isNew: true, preferred: size(10, 12) }), size(35, 30))
    )

    it('leaves a dimension alone when it already has the preferred size, even off the grid', () ->
      assert.deepEqual(run({ isNew: true, current: size(103, 41), preferred: size(103, 41) }), size(103, 41))
    )

  )

  describe('for an existing widget', () ->

    it('grows when the preferred size changed during the edit', () ->
      result = run({ preferredBefore: size(80, 20), preferred: size(142, 20) })
      assert.deepEqual(result, size(145, 40))
    )

    it('never shrinks', () ->
      assert.deepEqual(run({ preferredBefore: size(80, 60), preferred: size(60, 20) }), size(100, 40))
    )

    it('stays the same when the preferred size did not change', () ->
      assert.deepEqual(run({ preferredBefore: size(142, 60), preferred: size(142, 60) }), size(100, 40))
    )

    it('stays the same when there is no snapshot from before the edit', () ->
      assert.deepEqual(run({ preferred: size(142, 60) }), size(100, 40))
    )

    it('checks each dimension on its own', () ->
      assert.deepEqual(run({ preferredBefore: size(80, 60), preferred: size(142, 60) }), size(145, 40))
    )

  )

  it('only changes the dimensions the widget can be resized in', () ->
    result = run({ isNew: true, preferred: size(142, 61), canResize: { width: true, height: false } })
    assert.deepEqual(result, size(145, 40))
  )

  it('leaves a dimension with no preferred size alone', () ->
    assert.deepEqual(run({ isNew: true, preferred: size(null, 61) }), size(100, 65))
  )

)
