import { offsetFocus, sortAsIsolatedTabRegions, noWrapAround } from "./utils.js"
import { isMac } from "./utils.js"
import { Keybind, KeybindGroup } from "./keybind.js"

modKey = if isMac then "command" else "ctrl"

keybinds = [
  new KeybindGroup(
    "General Shortcuts",
    undefined,
    [],
    [
      new Keybind(
        "focus:clear",
        () -> document.activeElement?.blur()
        ["escape"],
        { description: "Clear focus from the current element."}
      ),
      new Keybind(
        "toggle:help",
        (ractive, event) -> ractive.fire('toggle-help', event),
        ["#{modKey}+h", "?", "shift+?", "f1"],
        { description: "Show help." }
      ),
      new Keybind(
        "toggle:editing",
        (ractive, event) -> ractive.fire('toggle-interface-lock')
        ["#{modKey}+shift+l"],
        { description: "Toggle authoring mode for the model." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus:model-widgets",
        (ractive, event) -> ractive.fire('focus-first-widget')
        ["#{modKey}+0"],
        { description: "Focus the first widget in the model." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus-tab:console",
        (ractive, event) -> ractive.fire('set-tab', 'console', { active: true, focus: true })
        ["#{modKey}+1"],
        { description: "Focus the Console tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus-tab:code",
        (ractive, event) -> ractive.fire('set-tab', 'code', { active: true , focus: true })
        ["#{modKey}+2"],
        { description: "Focus the Code tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus-tab:info",
        (ractive, event) -> ractive.fire('set-tab', 'info', { active: true, focus: true })
        ["#{modKey}+3"],
        { description: "Focus the Info tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle-tab:console",
        (ractive, event) -> ractive.fire('set-tab', 'console', { active: 'toggle', focus: true })
        ["#{modKey}+shift+1"],
        { description: "Toggle the Console tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle-tab:code",
        (ractive, event) -> ractive.fire('set-tab', 'code', { active: 'toggle', focus: true })
        ["#{modKey}+shift+2"],
        { description: "Toggle the Code tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle-tab:info",
        (ractive, event) -> ractive.fire('set-tab', 'info', { active: 'toggle', focus: true })
        ["#{modKey}+shift+3"],
        { description: "Toggle the Info tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle:input-mode",
        () -> {},
        ["#{modKey}+i"],
        { description: "Toggle input mode for widgets with multiple input-modes (e.g. sliders)." },
        { bind: false }
      ),
      new Keybind(
        "widget:copy-current-value",
        () -> {},
        ["#{modKey}+c"],
        { description: "Copies the current widget's value to the clipboard (chooser, input, slider)." },
        { bind: false }
      ),
      new Keybind(
        "widget:paste-into-current-value",
        () -> {},
        ["#{modKey}+v"],
        { description: "Pastes the clipboard value into the current widget (slider)." },
        { bind: false }
      )
    ]
  ),
  new KeybindGroup(
    "Code Editor Shortcuts",
    "Available in the code editor.",
    [],
    [
      new Keybind(
        "find:usages",
        () -> {},
        ["#{modKey}+u"],
        { description: "Find all usages of selected text." },
        { bind: false }
      ),
      new Keybind(
        "un/comment:line",
        () -> {},
        ["#{modKey}+;"],
        { description: "Comment/Uncomment the current line." },
        { bind: false }
      ),
      new Keybind(
        "focus:previous:override",
        (_, event) ->
          if not ["TEXTAREA", "INPUT"].includes(document.activeElement.tagName) and offsetFocus(
            document.body, document.activeElement,
            -1, false, sortAsIsolatedTabRegions, noWrapAround
          )
            event?.preventDefault()
            event?.stopPropagation()
        ["shift+tab"],
        {
          hidden: true,
          description: "Override Tab key to move focus with a custom behavior. "
        },
      ),
      new Keybind(
        "focus:next:override",
        (_, event) ->
          if not ["TEXTAREA", "INPUT"].includes(document.activeElement.tagName) and offsetFocus(
            document.body, document.activeElement,
            1, false, sortAsIsolatedTabRegions, noWrapAround
          )
            event?.preventDefault()
            event?.stopPropagation()
        ["tab"],
        {
          hidden: true,
          description: "Override Tab key to move focus with a custom behavior. "
        },
      ),
      new Keybind(
        "focus:next",
        (ractive, event) ->
          if offsetFocus(document.body, document.activeElement, 1, true)
            event?.preventDefault()
        ["alt+t"],
        { description: "Alternative to Tab key." }
      ),
      new Keybind(
        "focus:previous",
        (ractive, event) ->
          if offsetFocus(document.body, document.activeElement, -1, true)
            event?.preventDefault()
        ["alt+shift+t"],
        { description: "Alternative to Shift+Tab key." }
      )
    ]
  ),
  new KeybindGroup(
    "Authoring Mode Shortcuts",
    "Available when authoring the model.",
    [(ractive) -> ractive.get('stateName').startsWith('authoring')],
    [
      new Keybind(
        "widget:toggle-resizer-visibility",
        (ractive) -> ractive.fire('hide-resizer')
        ["#{modKey}+shift+h"],
        { description: "Show/hide the widget resizer." }
      ),
      new Keybind(
        "widget:close/deselect",
        (ractive) -> ractive.fire('deselect-widgets'),
        ["Escape"],
        { description: "Close the context menu or deselect any selected widget." }
      ),
      new Keybind(
        "widget:move-freely",
        (ractive, event) -> ractive.fire('move-widget-freely', event),
        ["#{modKey}"],
        { description: "Move the selected widget freely." },
        { bind: false }
      ),
      new Keybind(
        "widget:nudge",
        (ractive, _, combo) -> ractive.fire('nudge-widget', combo),
        ["up", "down", "left", "right"],
        { description: "Nudge the selected widget in any direction." },
        { options: { }}
      ),
      new Keybind(
        "widget:nudge",
        (ractive, _, combo) ->
          ractive.fire('nudge-widget', combo.replace("shift+", ""), event.shiftKey)
        ["shift+up", "shift+down", "shift+left", "shift+right"],
        { description: "Nudge the selected widget farther in any direction." },
        { options: { }}
      ),
      new Keybind(
        "widget:delete",
        (ractive) -> ractive.fire('delete-selected'),
        ["del", "backspace"],
        { description: "Delete the selected widget." }
      ),
      new Keybind(
        "*:context-menu",
        (ractive, event) -> ractive.fire('trigger-context-menu', event),
        ["#{modKey}+shift+f10", "menu", "#{modKey}+alt+x"],
        { description: "Open the context menu for the focused element." }
      ),
      new Keybind(
        "app:show-add-widget-menu",
        (ractive, event) -> ractive.fire('show-add-widget-menu', event),
        ["#{modKey}+alt+a"],
        { description: "Show the Add Widget menu." }
      )
    ]
  ),
  new KeybindGroup(
    "Edit Form Shortcuts",
    "Available when editing a widget's properties.",
    [(ractive) -> ractive.get('stateName').startsWith('authoring')],
    [
      new Keybind(
        "form:submit",
        () => {},
        ["Enter"],
        { description: "Submit the form." },
        { bind: false }
      ),
      new Keybind(
        "form:close",
        () => {},
        ["Escape"],
        { description: "Close the form and ignore any changes made." },
        { bind: false }
      )
    ]
  )
]

export { keybinds }
