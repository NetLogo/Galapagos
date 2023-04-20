import { NamespaceStorage } from "./namespace-storage.js"

SETTINGS_STORAGE_VERSION = 1

# (Storage) => NamespaceStorage
initSettingsStorage = (localStorage) ->
  storage = new NamespaceStorage('netLogoWebSettings', localStorage)
  if storage.hasKey('version') and storage.get('version') > SETTINGS_STORAGE_VERSION
    message = 'Unable to read settings, somehow the stored version is higher than the latest format version?'
    console.error(message, storage.inProgress, SETTINGS_STORAGE_VERSION)

  # This is version 1 so not much updating to do, but here would be where we'd read through any stored settings and
  # get them running on the latest version... -Jeremy B April 2023

  storage.set('version', SETTINGS_STORAGE_VERSION)

  storage

export { initSettingsStorage }
