import { locales } from './settings-controller.js'

getOrElse = (params, key, def) ->
  if params.has(key)
    params.get(key)
  else
    def

parseFloatOrElse = (str, def) ->
  f = Number.parseFloat(str)
  if Number.isNaN(f) then def else f

clamp = (min, max, val) ->
  Math.max(min, Math.min(max, val))

updatedLocales = locales.map((locale) ->
  newLocale = {}
  for key, value of locale
    newLocale[key] = value
  newLocale
)

class Settings

  constructor: ->
    @locale = navigator.language.replace('-', '_').toLowerCase()

    exactMatch = updatedLocales.find((locale) => @locale is locale.code)

    if exactMatch
      @locale = exactMatch.code
    else
      matchingLocale = locales.find((locale) => @locale.startsWith(locale.languageCode))
      if matchingLocale
        @locale = matchingLocale.code

  useVerticalLayout: true

  speed: 0.0

  workInProgress: {
    enabled:    true
    storageTag: ''
  }

  events: {
    enableDebug:          false
    enableIframeRelay:    false
    iframeRelayEvents:    ''
    iframeRelayEventsTag: ''
  }

  queries: {
    enableDebug: false
  }

  # (NamespaceStorage) => Unit
  applyStorage: (storage) ->
    if storage.hasKey('locale')
      @locale = storage.get('locale')

    if storage.hasKey('useVerticalLayout')
      @useVerticalLayout = storage.get('useVerticalLayout')

    if storage.hasKey('workInProgress.enabled')
      @workInProgress.enabled = storage.get('workInProgress.enabled')

    return

  # (URLSearchParams) => Unit
  applyQueryParams: (params) ->
    if params.has('locale')
      @locale = params.get('locale').replace('-', '_').toLowerCase()

    if params.has('tabs')
      @useVerticalLayout = not (params.get('tabs') is 'right')

    if params.has('speed')
      speedString = params.get('speed')
      @speed = clamp(-1, 1, parseFloatOrElse(speedString, 0.0))

    @workInProgress.enabled = not params.has('disableWorkInProgress') and @workInProgress.enabled
    if params.has('storageTag')
      @workInProgress.storageTag = params.get('storageTag')

    @events.enableDebug       = params.has('debugEvents') or @events.enableDebug
    @events.enableIframeRelay = params.has('relayIframeEvents') or @events.enableIframeRelay
    if params.has('relayIframeEvents')
      @events.iframeRelayEvents = params.get('relayIframeEvents')
    if params.has('relayIframeEventsTag')
      @events.iframeRelayEventsTag = params.get('relayIframeEventsTag')

    @queries.enableDebug = params.has('debugQueries') or @queries.enableDebug

    return

export default Settings
