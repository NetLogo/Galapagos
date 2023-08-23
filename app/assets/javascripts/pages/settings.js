import { createSettingsRactive } from '/settings-controller.js'
import { initSettingsStorage } from "/settings-storage.js";
import { NamespaceStorage } from '/namespace-storage.js';


const elementId = 'nlw-settings'
const container = document.getElementById(elementId)

var ls
try {
  ls = globalThis.localStorage
} catch (exception) {
  ls = fakeStorage()
}

const settingsStorage = initSettingsStorage(ls)
const wipStorage = new NamespaceStorage('netLogoWebWip', ls)

globalThis.ractive = createSettingsRactive(container, settingsStorage, wipStorage)