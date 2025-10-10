import { createKeyMetadata } from "./keyboard-listener.js"
import { offsetFocus } from "./utils.js"

keybinds = [
  {
    id: "focus:clear"
    callback: () -> document.activeElement?.blur()
    metadata: createKeyMetadata("Escape", "Clear focus from the current element.")
  },
  {
    id: "focus:next"
    callback: (_, event) ->
      if offsetFocus(document.body, document.activeElement, 1)
        event?.preventDefault()
    metadata: createKeyMetadata("Ctrl+T", "Alternative to Tab key (for use in Code editor).")
  },
  {
    id: "focus:previous"
    callback: (_, event) ->
      if offsetFocus(document.body, document.activeElement, -1)
        event?.preventDefault()
    metadata: createKeyMetadata("Ctrl+Shift+T", "Alternative to Shift+Tab key (for use in Code editor).")
  },
  {
    id: "toggle-tab:console"
    callback: (skeleton, event) -> skeleton.setTab('console', { active: 'toggle', focus: true })
    metadata: createKeyMetadata("Ctrl+1", "Toggle the Console tab.")
  },
  {
    id: "toggle-tab:code"
    callback: (skeleton, event) -> skeleton.setTab('code', { active: 'toggle', focus: true })
    metadata: createKeyMetadata("Ctrl+2", "Toggle the Code tab.")
  },
  {
    id: "toggle-tab:info"
    callback: (skeleton, event) -> skeleton.setTab('info', { active: 'toggle', focus: true })
    metadata: createKeyMetadata("Ctrl+3", "Toggle the Info tab.")
  },
  {
    id: "focus-tab:console",
    callback: (skeleton, event) -> skeleton.setTab('console', { active: true, focus: true })
    metadata: createKeyMetadata("Ctrl+Shift+1", "Focus the Console tab.")
  },
  {
    id: "focus-tab:code",
    callback: (skeleton, event) -> skeleton.setTab('code', { active: true, focus: true })
    metadata: createKeyMetadata("Ctrl+Shift+2", "Focus the Code tab.")
  },
  {
    id: "focus-tab:info",
    callback: (skeleton, event) -> skeleton.setTab('info', { active: true, focus: true })
    metadata: createKeyMetadata("Ctrl+Shift+3", "Focus the Info tab.")
  },
  {
    id: "toggle:editing",
    callback: (skeleton, event) -> skeleton.set('isEditing', not skeleton.get('isEditing'))
    metadata: createKeyMetadata("Ctrl+E", "Toggle editing mode for the Info tab.")
  },
  {
    id: "toggle:help",
    callback: (skeleton, event) -> skeleton.set('isHelpVisible', not skeleton.get('isHelpVisible'))
    metadata: createKeyMetadata("Ctrl+H", "Show help.")
  },
  {
    id: "toggle:keyboard-help",
    callback: (skeleton, event) -> skeleton.toggleKeyboardHelp()
    metadata: createKeyMetadata("F1", "Show keyboard shortcuts help.")
  }
]

export { keybinds }
