import { createSettingsRactive } from '/settings-controller.js'

const elementId = 'nlw-settings'
const container = document.getElementById(elementId)
globalThis.ractive = createSettingsRactive(container)
