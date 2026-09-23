import assert from 'assert'
import { rectFromCorners, rectsTouch } from '../../../main/beak/widgets/rectangles.js'

describe('rectangles', () ->

  describe('rectFromCorners()', () ->

    it('makes the same rectangle from any pair of opposite corners', () ->
      expected = { x: 10, y: 20, width: 30, height: 40 }
      assert.deepEqual(rectFromCorners(10, 20, 40, 60), expected)
      assert.deepEqual(rectFromCorners(40, 60, 10, 20), expected)
      assert.deepEqual(rectFromCorners(40, 20, 10, 60), expected)
      assert.deepEqual(rectFromCorners(10, 60, 40, 20), expected)
    )

  )

  describe('rectsTouch()', () ->

    widget = { x: 100, y: 100, width: 50, height: 20 }

    it('is true when one rectangle holds the other', () ->
      assert.equal(rectsTouch({ x: 0, y: 0, width: 500, height: 500 }, widget), true)
      assert.equal(rectsTouch({ x: 110, y: 105, width: 5, height: 5 }, widget), true)
    )

    it('is true when they only partly overlap', () ->
      assert.equal(rectsTouch({ x: 140, y: 115, width: 50, height: 50 }, widget), true)
      assert.equal(rectsTouch({ x: 50, y: 50, width: 60, height: 60 }, widget), true)
    )

    it('is true when they share only an edge', () ->
      assert.equal(rectsTouch({ x: 150, y: 100, width: 10, height: 10 }, widget), true)
      assert.equal(rectsTouch({ x: 100, y: 80, width: 10, height: 20 }, widget), true)
    )

    it('is true for a box with no width that crosses the rectangle', () ->
      assert.equal(rectsTouch({ x: 120, y: 0, width: 0, height: 300 }, widget), true)
    )

    it('is false when they are apart on either axis', () ->
      assert.equal(rectsTouch({ x: 151, y: 100, width: 10, height: 10 }, widget), false)
      assert.equal(rectsTouch({ x: 100, y: 121, width: 10, height: 10 }, widget), false)
      assert.equal(rectsTouch({ x: 0, y: 0, width: 99, height: 500 }, widget), false)
      assert.equal(rectsTouch({ x: 0, y: 0, width: 500, height: 99 }, widget), false)
    )

  )

)
