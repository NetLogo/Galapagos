import assert from 'assert'
import {
  comparePositionsRowMajor, setSortingKeys, sortWidgetObjects
} from '../../../../main/beak/widgets/accessibility/widgets.js'

# Only the position and size of a widget matter to the sorting.
box = (x, y, width = 10, height = 10) -> { x, y, width, height }

describe('widget sorting', () ->

  describe('#comparePositionsRowMajor()', () ->

    it('puts the higher widget first', () ->
      assert.ok(comparePositionsRowMajor(box(50, 0), box(0, 10)) < 0)
    )

    it('puts the leftmost of two widgets in the same row first', () ->
      assert.ok(comparePositionsRowMajor(box(0, 10), box(50, 10)) < 0)
    )

    it('calls two widgets in the same place with the same size equal', () ->
      assert.equal(comparePositionsRowMajor(box(0, 0), box(0, 0)), 0)
    )

  )

  describe('#sortWidgetObjects()', () ->

    it('keeps each widget with the key it has in the object', () ->
      widgetObj = { 0: box(0, 30), 2: box(0, 0), 5: box(0, 10) }

      sorted = sortWidgetObjects(widgetObj)

      assert.deepEqual(sorted.map( ({ key }) -> key ), ['2', '5', '0'])
      assert.deepEqual(sorted.map( ({ widget }) -> widget ), [widgetObj[2], widgetObj[5], widgetObj[0]])
    )

  )

  describe('#setSortingKeys()', () ->

    it('numbers the widgets in row-major order', () ->
      widgetObj = { 0: box(50, 0), 1: box(0, 0), 2: box(0, 20) }

      setSortingKeys(widgetObj)

      assert.equal(widgetObj[0].sortingKey, 1)
      assert.equal(widgetObj[1].sortingKey, 0)
      assert.equal(widgetObj[2].sortingKey, 2)
    )

    it('handles keys with gaps in them, as deleting a widget leaves behind', () ->
      widgetObj = { 0: box(0, 0), 2: box(0, 50), 5: box(0, 20) }

      setSortingKeys(widgetObj)

      assert.equal(widgetObj[0].sortingKey, 0)
      assert.equal(widgetObj[5].sortingKey, 1)
      assert.equal(widgetObj[2].sortingKey, 2)
    )

    it('does nothing to an empty object', () ->
      widgetObj = {}

      setSortingKeys(widgetObj)

      assert.deepEqual(widgetObj, {})
    )

  )

)
