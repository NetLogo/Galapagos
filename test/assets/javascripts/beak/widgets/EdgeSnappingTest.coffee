import assert from 'assert'
import { findSnap, edgesOf } from '../../../main/beak/widgets/edge-snapping.js'

describe('edge snapping', () ->

  describe('edgesOf()', () ->

    it('lists edges as xs and ys, and centerlines as cxs and cys', () ->
      edges = edgesOf([{ x: 10, y: 20, width: 30, height: 40 }, { x: 100, y: 200, width: 6, height: 8 }])
      assert.deepEqual(edges, { xs: [10, 40, 100, 106], ys: [20, 60, 200, 208], cxs: [25, 103], cys: [40, 204] })
    )

    it('rounds centerlines of odd-sized rects to whole pixels', () ->
      edges = edgesOf([{ x: 10, y: 20, width: 5, height: 7 }])
      assert.deepEqual([edges.cxs, edges.cys], [[13], [24]])
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

    it('snaps centerlines only to centerlines', () ->
      withCenters = { xs: [100], ys: [], cxs: [150], cys: [] }
      assert.equal(findSnap({ xs: [149], ys: [] }, withCenters, 5).x, null)
      assert.equal(findSnap({ xs: [], ys: [], cxs: [101], cys: [] }, withCenters, 5).x, null)
      assert.deepEqual(findSnap({ xs: [], ys: [], cxs: [148], cys: [] }, withCenters, 5).x, { delta: 2, at: 150 })
    )

    it('takes the closer of an edge snap and a centerline snap', () ->
      withCenters = { xs: [100], ys: [], cxs: [150], cys: [] }
      assert.deepEqual(findSnap({ xs: [97], ys: [], cxs: [149], cys: [] }, withCenters, 5).x, { delta: 1, at: 150 })
      assert.deepEqual(findSnap({ xs: [99], ys: [], cxs: [147], cys: [] }, withCenters, 5).x, { delta: 1, at: 100 })
    )

    it('uses 5 as the threshold by default', () ->
      assert.notEqual(findSnap({ xs: [95], ys: [] }, candidates).x, null)
      assert.equal(findSnap({ xs: [94], ys: [] }, candidates).x, null)
    )

  )

)
