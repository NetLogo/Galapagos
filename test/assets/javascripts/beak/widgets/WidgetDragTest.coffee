import assert from 'assert'
import { snapDragOffset } from '../../../main/beak/widgets/handle-widget-selection.js'
import { edgesOf }        from '../../../main/beak/widgets/edge-snapping.js'

describe('snapDragOffset()', () ->

  groupBox   = { x: 230, y: 342, width: 341, height: 235 }
  grabbed    = { x0: 230, y0: 342 }
  candidates = edgesOf([{ x: 350, y: 100, width: 102, height: 60 }])

  it('keeps a centerline snap on whole pixels when the pointer moved a fraction', () ->
    { dx, snap } = snapDragOffset(groupBox, grabbed, candidates, { dx: 1.92529296875, dy: 0.4 })
    assert.equal(snap.x.at, 401)
    assert.equal(dx, 1)
  )

  it('keeps an edge snap on whole pixels', () ->
    { dx, snap } = snapDragOffset(groupBox, grabbed, candidates, { dx: -114.4, dy: 0 })
    assert.equal(snap.x.at, 452)
    assert.equal(groupBox.x + groupBox.width + dx, 452)
  )

  it('snaps to the grid when nothing is near', () ->
    { dx, dy } = snapDragOffset(groupBox, grabbed, candidates, { dx: 31.7, dy: 12.3 })
    assert.deepEqual([grabbed.x0 + dx, grabbed.y0 + dy], [260, 355])
  )

)
