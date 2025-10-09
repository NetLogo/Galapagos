export accessibilitySelectors = Object.freeze({
  "form": ["input", "select", "textarea", "button", "object"]
          .map( (tag) -> "#{tag}:not([disabled]):not([aria-disabled='true'])" ),
  "link": ["a[href]", "area[href]"],
  "media": ["audio[controls]", "video[controls]", "iframe", "embed"],
  "contenteditable": ['[contenteditable]:not([contenteditable="false"])'],
  "role": [
    '[role="button"]', '[role="link"]', '[role="textbox"]',
    '[role="search"]', '[role="combobox"]', '[role="listbox"]',
    '[role="menu"]', '[role="menubar"]'
  ].map( (role) -> "#{role}:not([aria-disabled='true']):not([disabled])" ),
  "tabindex": ['*[tabindex]:not([tabindex="-1"]):not([disabled])']
})

export getAllFocusableElements = (container) ->
  selector = Object.values(accessibilitySelectors).flat().join(', ')
  elements = Array.from(container.querySelectorAll(selector))
                  .filter((el) -> el.offsetWidth > 0 or el.offsetHeight > 0)
  elements

export offsetFocus = (container, element, offset) ->
  focusables = getAllFocusableElements(container)
  index = focusables.indexOf(element)
  if index isnt -1
    newIndex = (index + offset + focusables.length) % focusables.length
    focusables[newIndex]?.focus()
    return true
  return false
