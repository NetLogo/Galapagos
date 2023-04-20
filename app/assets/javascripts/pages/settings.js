import { createSettingsRactive } from '/settings-controller.js'
import { initSettingsStorage } from "/settings-storage.js";

const elementId = 'nlw-settings'
const container = document.getElementById(elementId)

var ls
try {
  ls = globalThis.localStorage
} catch (exception) {
  ls = fakeStorage()
}

const settingsStorage = initSettingsStorage(ls)

globalThis.ractive = createSettingsRactive(container, settingsStorage)
