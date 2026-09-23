import assert from 'assert'
import { findSnap, edgesOf } from '../../../main/beak/widgets/edge-snapping.js'

describe('edge snapping', () ->

  describe('edgesOf()', () ->

    it('lists the left and right edges as xs, and the top and bottom edges as ys', () ->
      edges = edgesOf([{ x: 10, y: 20, width: 30, height: 40 }, { x: 100, y: 200, width: 5, height: 6 }])
      assert.deepEqual(edges, { xs: [10, 40, 100, 105], ys: [20, 60, 200, 206] })
    )

  )

  describe('findSnap()', () ->

    candidates = { xs: [100, 200], ys: [50, 80] }

    it('snaps an edge that is within the threshold', () ->
      snap = findSnap({ xs: [97], ys: [] }, candidates, 5)
      assert.deepEqual(snap.x, { delta: 3, at: 100 })
      assert.equal(snap.y, null)
    )

    it('snaps an edge at exactly the threshold, but not past it', () ->
      assert.deepEqual(findSnap({ xs: [205], ys: [] }, candidates, 5).x, { delta: -5, at: 200 })
      assert.equal(findSnap({ xs: [206], ys: [] }, candidates, 5).x, null)
    )

    it('snaps each axis on its own', () ->
      snap = findSnap({ xs: [102], ys: [300] }, candidates, 5)
      assert.deepEqual(snap.x, { delta: -2, at: 100 })
      assert.equal(snap.y, null)
    )

    it('takes the closest pair when several moving edges are in range', () ->
      snap = findSnap({ xs: [96, 199], ys: [47, 79] }, candidates, 5)
      assert.deepEqual(snap.x, { delta: 1, at: 200 })
      assert.deepEqual(snap.y, { delta: 1, at: 80 })
    )

    it('takes the closest candidate when several are in range', () ->
      snap = findSnap({ xs: [52], ys: [] }, { xs: [48, 53], ys: [] }, 5)
      assert.deepEqual(snap.x, { delta: 1, at: 53 })
    )

    it('never snaps an axis with no moving edges', () ->
      snap = findSnap({ xs: [], ys: [] }, candidates, 5)
      assert.deepEqual(snap, { x: null, y: null })
    )

    it('uses 5 as the threshold by default', () ->
      assert.notEqual(findSnap({ xs: [95], ys: [] }, candidates).x, null)
      assert.equal(findSnap({ xs: [94], ys: [] }, candidates).x, null)
    )

  )

)
