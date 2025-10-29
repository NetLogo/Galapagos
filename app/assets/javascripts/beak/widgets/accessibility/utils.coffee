noFocusSelectors =  [
  ':not([hidden])',
  ':not([disabled])',
  ':not([aria-hidden="true"])',
  ':not([aria-disabled="true"])',
  ':not([tabindex="-1"])',
]

unlessNoFocus = (selector) ->
  "#{selector}#{noFocusSelectors.join('')}"


accessibilitySelectors = Object.freeze(
  Object.fromEntries(
    [
      ["form", ["input", "select", "textarea", "button", "object"]],
      ["link", ["a[href]", "area[href]"]],
      ["media", ["audio[controls]", "video[controls]", "iframe", "embed"]],
      ["contenteditable", ['[contenteditable]:not([contenteditable="false"])']],
      ["role", [
        '[role="button"]', '[role="link"]', '[role="textbox"]',
        '[role="search"]', '[role="combobox"]', '[role="listbox"]',
        '[role="menu"]', '[role="menubar"]'
      ]],
      ["tabindex", ['[tabindex]']]
    ].map(([key, selectors]) -> [key, selectors.map(unlessNoFocus)])
  )
)

# (HTMLElement, HTMLElement) => Number
sortByTabIndex = (a, b) ->
  aTabIndex = parseInt(a.getAttribute('tabindex') or '0')
  bTabIndex = parseInt(b.getAttribute('tabindex') or '0')
  if aTabIndex < bTabIndex
    -1
  else if aTabIndex > bTabIndex
    1
  else
    0

# (HTMLElement) => Array[HTMLElement]
getAllFocusableElements = (container) ->
  selector = Object.values(accessibilitySelectors).flat().join(', ')
  elements = Array.from(container.querySelectorAll(selector))
                  .filter((el) -> el.offsetWidth > 0 or el.offsetHeight > 0)
  elements.sort(sortByTabIndex)

# (HTMLElement, HTMLElement, Number) => Boolean
offsetFocus = (container, element, offset) ->
  focusables = getAllFocusableElements(container)
  index = focusables.indexOf(element)
  if index isnt -1
    newIndex = (index + offset + focusables.length) % focusables.length
    focusables[newIndex]?.focus()
  index isnt -1

isMac = window.navigator.platform.startsWith('Mac')

# HTMLKeyboardEvent => Boolean
isToggleKeydownEvent = (event) ->
  return event.key in [' ', 'Enter', 'Spacebar']

# (HTMLElement, (Object) => Void) => Void
ractiveAccessibleClickEvent = (node, fire) ->
  clickHandler = (event) ->
    fire({ node: node, original: event })
    return

  keydownHandler = (event) ->
    if isToggleKeydownEvent(event)
      event.preventDefault()
      fire({ node: node, original: event })
    return

  node.addEventListener('click', clickHandler, false)
  node.addEventListener('keydown', keydownHandler, false)

  return {
    teardown: ->
      node.removeEventListener('click', clickHandler, false)
      node.removeEventListener('keydown', keydownHandler, false)
  }

export {
  noFocusSelectors,
  unlessNoFocus,
  accessibilitySelectors,
  sortByTabIndex,
  getAllFocusableElements,
  offsetFocus,
  isMac,
  isToggleKeydownEvent,
  ractiveAccessibleClickEvent
}
