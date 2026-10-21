import assert from 'assert'
import handleWidgetTooltips from '../../../main/beak/widgets/widget-tooltips.js'

describe('handleWidgetTooltips()', () ->

  container = undefined

  beforeEach(() ->
    container = document.createElement('div')
    document.body.appendChild(container)
    handleWidgetTooltips(container)
  )

  afterEach(() ->
    container.remove()
  )

  makeWidget = (text, scrollWidth, clientWidth) ->
    widget = document.createElement('label')
    widget.className = 'netlogo-widget netlogo-chooser'
    label = document.createElement('span')
    label.className   = 'netlogo-label'
    label.textContent = text
    Object.defineProperty(label, 'scrollWidth', { value: scrollWidth, configurable: true })
    Object.defineProperty(label, 'clientWidth', { value: clientWidth, configurable: true })
    control = document.createElement('select')
    widget.append(label, control)
    container.appendChild(widget)
    { widget, label, control }

  hover = (elem) ->
    elem.dispatchEvent(new window.Event('pointerover', { bubbles: true }))

  it('shows the full label on the whole widget when the label is truncated', () ->
    { widget, control } = makeWidget(' initial-number-of-wolves ', 180, 90)
    hover(control)
    assert.equal(widget.title, 'initial-number-of-wolves')
  )

  it('shows no tooltip when the label fits', () ->
    { widget, label } = makeWidget('wolves', 40, 90)
    hover(label)
    assert.equal(widget.hasAttribute('title'), false)
  )

  it('removes the tooltip once the label fits again', () ->
    { widget, label } = makeWidget('initial-number-of-wolves', 180, 90)
    hover(label)
    Object.defineProperty(label, 'clientWidth', { value: 200, configurable: true })
    hover(label)
    assert.equal(widget.hasAttribute('title'), false)
  )

  it('ignores widgets without a label', () ->
    widget = document.createElement('div')
    widget.className = 'netlogo-widget netlogo-note'
    container.appendChild(widget)
    hover(widget)
    assert.equal(widget.hasAttribute('title'), false)
  )

)
