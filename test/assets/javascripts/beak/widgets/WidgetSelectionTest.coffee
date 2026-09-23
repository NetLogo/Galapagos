import assert from 'assert'
import WidgetSelection from '../../../main/beak/widgets/widget-selection.js'

fakeWidget = (name) -> {
  name:       name
  isSelected: false
  destroyed:  false
  set:        (key, value) -> @[key] = value
}

describe('WidgetSelection', () ->

  makeSelection = () ->
    changes   = []
    selection = new WidgetSelection( (components) -> changes.push(components) )
    [selection, changes]

  describe('#set()', () ->

    it('selects the one widget and deselects everyone else', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.set(a)
      selection.set(b)

      assert.deepEqual(selection.all(), [b])
      assert.equal(a.isSelected, false)
      assert.equal(b.isSelected, true)
    )

    it('reports each change', () ->
      [selection, changes] = makeSelection()
      a                    = fakeWidget('a')

      selection.set(a)

      assert.equal(changes.length, 1)
      assert.deepEqual(changes[0], [a])
    )

  )

  describe('#toggle()', () ->

    it('adds a widget that is not selected', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.set(a)
      selection.toggle(b)

      assert.deepEqual(selection.all(), [a, b])
      assert.equal(selection.size(), 2)
      assert.equal(b.isSelected, true)
    )

    it('removes a widget that is already selected', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.set(a)
      selection.toggle(b)
      selection.toggle(a)

      assert.deepEqual(selection.all(), [b])
      assert.equal(a.isSelected, false)
    )

  )

  describe('#add()', () ->

    it('adds only the widgets that are new', () ->
      [selection, changes] = makeSelection()
      [a, b, c]            = [fakeWidget('a'), fakeWidget('b'), fakeWidget('c')]

      selection.set(a)
      selection.add([a, b, c])

      assert.deepEqual(selection.all(), [a, b, c])
    )

    it('does nothing when every widget is already selected', () ->
      [selection, changes] = makeSelection()
      a                    = fakeWidget('a')

      selection.set(a)
      selection.add([a])

      assert.equal(changes.length, 1)
    )

  )

  describe('#replace()', () ->

    it('selects exactly the given widgets', () ->
      [selection, _] = makeSelection()
      [a, b, c]      = [fakeWidget('a'), fakeWidget('b'), fakeWidget('c')]

      selection.set(a)
      selection.replace([b, c])

      assert.deepEqual(selection.all(), [b, c])
      assert.equal(a.isSelected, false)
      assert.equal(b.isSelected, true)
      assert.equal(c.isSelected, true)
    )

    it('drops duplicates', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.replace([a, b, a])

      assert.deepEqual(selection.all(), [a, b])
    )

    it('does not report a change when the selection is the same', () ->
      [selection, changes] = makeSelection()
      [a, b]               = [fakeWidget('a'), fakeWidget('b')]

      selection.replace([a, b])
      selection.replace([a, b])

      assert.equal(changes.length, 1)
    )

  )

  describe('#clear()', () ->

    it('deselects everything', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.set(a)
      selection.toggle(b)
      selection.clear()

      assert.deepEqual(selection.all(), [])
      assert.equal(a.isSelected, false)
      assert.equal(b.isSelected, false)
    )

    it('leaves a destroyed widget alone', () ->
      [selection, _] = makeSelection()
      a              = fakeWidget('a')

      selection.set(a)
      a.destroyed  = true
      a.isSelected = 'untouched'
      selection.clear()

      assert.equal(a.isSelected, 'untouched')
    )

  )

  describe('locking', () ->

    it('refuses changes while locked', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.set(a)
      selection.lock()
      selection.set(b)
      selection.clear()

      assert.deepEqual(selection.all(), [a])
    )

    it('takes changes again once unlocked', () ->
      [selection, _] = makeSelection()
      [a, b]         = [fakeWidget('a'), fakeWidget('b')]

      selection.set(a)
      selection.lock()
      selection.unlock()
      selection.set(b)

      assert.deepEqual(selection.all(), [b])
    )

  )

)
