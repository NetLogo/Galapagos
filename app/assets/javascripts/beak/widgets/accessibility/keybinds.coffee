import { offsetFocus } from "./utils.js"
import { isMac } from "./utils.js"
import { Keybind, KeybindGroup } from "./keybind.js"

platformCmd = if isMac then "command" else "ctrl"

keybinds = [
  new KeybindGroup(
    "General Shortcuts",
    undefined,
    [],
    [
      new Keybind(
        "focus:clear",
        () -> document.activeElement?.blur()
        ["Escape"],
        { description: "Clear focus from the current element."}
      ),
      new Keybind(
        "focus:next",
        (ractive, event) ->
          if offsetFocus(document.body, document.activeElement, 1)
            event?.preventDefault()
        ["#{platformCmd}+t"],
        { description: "Alternative to Tab key (for use in Code editor)." }
      ),
      new Keybind(
        "focus:previous",
        (ractive, event) ->
          if offsetFocus(document.body, document.activeElement, -1)
            event?.preventDefault()
        ["#{platformCmd}+shift+t"],
        { description: "Alternative to Shift+Tab key (for use in Code editor)." }
      ),
      new Keybind(
        "toggle:keyboard-help",
        (ractive, event) -> ractive.fire('toggle-keyboard-help')
        ["f1"],
        { description: "Show keyboard shortcuts help." }
      ),
      new Keybind(
        "toggle:help",
        (ractive, event) -> ractive.set('isHelpVisible', not ractive.get('isHelpVisible'))
        ["#{platformCmd}+h"],
        { description: "Show help." }
      ),
      new Keybind(
        "toggle:editing",
        (ractive, event) -> ractive.set('isEditing', not ractive.get('isEditing'))
        ["#{platformCmd}+e"],
        { description: "Toggle authoring mode for the model." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle-tab:console",
        (ractive, event) -> ractive.fire('set-tab', 'console', { active: 'toggle', focus: true })
        ["#{platformCmd}+1"],
        { description: "Toggle the Console tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle-tab:code",
        (ractive, event) -> ractive.fire('set-tab', 'code', { active: 'toggle', focus: true })
        ["#{platformCmd}+2"],
        { description: "Toggle the Code tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "toggle-tab:info",
        (ractive, event) -> ractive.fire('set-tab', 'info', { active: 'toggle', focus: true })
        ["#{platformCmd}+3"],
        { description: "Toggle the Info tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus-tab:console",
        (ractive, event) -> ractive.fire('set-tab', 'console', { active: true, focus: true })
        ["#{platformCmd}+shift+1"],
        { description: "Focus the Console tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus-tab:code",
        (ractive, event) -> ractive.fire('set-tab', 'code', { active: true , focus: true })
        ["#{platformCmd}+shift+2"],
        { description: "Focus the Code tab." },
        { preventDefault: true }
      ),
      new Keybind(
        "focus-tab:info",
        (ractive, event) -> ractive.fire('set-tab', 'info', { active: true, focus: true })
        ["#{platformCmd}+shift+3"],
        { description: "Focus the Info tab." },
        { preventDefault: true }
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
        ["#{platformCmd}+u"],
        { description: "Find all usages of selected text." },
        { bind: false }
      ),
      new Keybind(
        "un/comment:line",
        () -> {},
        ["#{platformCmd}+;"],
        { description: "Comment/Uncomment the current line." },
        { bind: false }
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
        ["#{platformCmd}+shift+h"],
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
        ["#{platformCmd}"],
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
        "widget:delete",
        (ractive) -> not isMac and ractive.fire('delete-selected'),
        ["del", "backspace"],
        { description: "Delete the selected widget." }
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
