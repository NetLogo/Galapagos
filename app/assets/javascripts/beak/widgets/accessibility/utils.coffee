noFocusSelectors =  [
  ':not([hidden])',
  ':not([disabled])',
  ':not([aria-hidden="true"])',
  ':not([aria-disabled="true"])',
  ':not([tabindex="-1"])',
]

# (String) => String
unlessNoFocus = (selector) ->
  "#{selector}#{noFocusSelectors.join('')}"

# { [key: String]: Array[String] }
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

# @Type SortFunction = (HTMLElement, HTMLElement) => Number
# SortFunction
sortByTabIndex = (a, b) ->
  aTabIndex = parseInt(a.getAttribute('tabindex') or '0')
  bTabIndex = parseInt(b.getAttribute('tabindex') or '0')
  if aTabIndex < bTabIndex
    -1
  else if aTabIndex > bTabIndex
    1
  else
    0

# @Type SortFunction = (HTMLElement, HTMLElement) => Number
# SortFunction
sortAsIsolatedTabRegions = (a, b) ->
  # An isolated tab region is one where all elements have
  # tabindex>0. Its boundaries are defined by elements with
  # tabindex=0.
  # e.g. (0*, 0**, 1, 3, 2, 0***, 0****, 5, 4, 0*****)
  #   -> (0*, 0**, 1, 2, 3, 0***, 0****, 4, 5, 0*****)
  aTabIndex = parseInt(a.getAttribute('tabindex') or '0')
  bTabIndex = parseInt(b.getAttribute('tabindex') or '0')

  if aTabIndex > 0 and bTabIndex > 0
    sortByTabIndex(a, b)
  else
    0

# @Type SortFunction = (HTMLElement, HTMLElement) => Number
# (HTMLElement, SortFunction?) => Array[HTMLElement]
getAllFocusableElements = (container, sortFn = sortByTabIndex) ->
  selector = Object.values(accessibilitySelectors).flat().join(', ')
  elements = Array.from(container.querySelectorAll(selector))
                  .filter((el) -> el.offsetWidth > 0 or el.offsetHeight > 0)
  elements.sort(sortFn)

# @Type IndexFunction = (Number, Number, Number) => Number | Undefined
# IndexFunction
wrapAround = (index, length, offset) ->
  if offset > 0
    (index + offset) % length
  else
    newIndex = (index + offset) % length
    if newIndex < 0 then length + newIndex else newIndex

# IndexFunction
noWrapAround = (index, length, offset) ->
  newIndex = index + offset
  if newIndex < 0 or newIndex >= length
    undefined
  else
    newIndex

# @Type SortFunction = (HTMLElement, HTMLElement) => Number
# (HTMLElement, HTMLElement, (Number)?, SortFunction?, IndexFunction?) => Boolean
offsetFocus = (
  container,
  element,
  offset,
  visible = false,
  sortFn = sortByTabIndex,
  indexFn = wrapAround
) ->
  focusables = getAllFocusableElements(container, sortFn)
  index = focusables.indexOf(element)
  newIndex = indexFn(index, focusables.length, offset)
  if index isnt -1 and newIndex?
    if visible
      focusElementVisible(focusables[newIndex])
    else
      focusables[newIndex]?.focus()
  index isnt -1 and newIndex?

isMac = window.navigator.platform.startsWith('Mac')

# HTMLKeyboardEvent => Boolean
isToggleKeydownEvent = (event) ->
  return event.key in [' ', 'Enter', 'Spacebar']

# (HTMLElement) => Void
focusElementVisible = (element) ->
  if element and element.focus
    element.contentEditable = true
    element.focus({ preventScroll: true, focusVisible: true })
    element.contentEditable = false
  return

export {
  noFocusSelectors,
  unlessNoFocus,
  accessibilitySelectors,
  sortByTabIndex,
  sortAsIsolatedTabRegions,
  getAllFocusableElements,
  wrapAround,
  noWrapAround,
  offsetFocus,
  isMac,
  isToggleKeydownEvent,
  focusElementVisible
}
