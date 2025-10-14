noFocusSelector =  [
  ':not([tabindex="-1"]):not([disabled]):not([aria-hidden="true"]):not([aria-disabled="true"])'
]

unlessNoFocus = (selector) ->
  "#{selector}#{noFocusSelector.join('')}"


export accessibilitySelectors = Object.freeze({
  "form": ["input", "select", "textarea", "button", "object"].map(unlessNoFocus),
  "link": ["a[href]", "area[href]"].map(unlessNoFocus),
  "media": ["audio[controls]", "video[controls]", "iframe", "embed"].map(unlessNoFocus),
  "contenteditable": ['[contenteditable]:not([contenteditable="false"])'].map(unlessNoFocus),
  "role": [
    '[role="button"]', '[role="link"]', '[role="textbox"]',
    '[role="search"]', '[role="combobox"]', '[role="listbox"]',
    '[role="menu"]', '[role="menubar"]'
  ].map(unlessNoFocus),
  "tabindex": ['[tabindex]'].map(unlessNoFocus)
})

sortByTabIndex = (a, b) ->
  aTabIndex = parseInt(a.getAttribute('tabindex') or '0')
  bTabIndex = parseInt(b.getAttribute('tabindex') or '0')
  if aTabIndex < bTabIndex then -1
  else if aTabIndex > bTabIndex then 1
  else 0

export getAllFocusableElements = (container) ->
  selector = Object.values(accessibilitySelectors).flat().join(', ')
  elements = Array.from(container.querySelectorAll(selector))
                  .filter((el) -> el.offsetWidth > 0 or el.offsetHeight > 0)
  elements.sort(sortByTabIndex)
  return elements

export offsetFocus = (container, element, offset) ->
  focusables = getAllFocusableElements(container)
  index = focusables.indexOf(element)
  if index isnt -1
    newIndex = (index + offset + focusables.length) % focusables.length
    focusables[newIndex]?.focus()
    return true
  return false

export isMac = window.navigator.platform.startsWith('Mac')
