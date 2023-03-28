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

class Settings

  locale: "en_us"

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

  # (URLSearchParams) => Settings
  @fromQueryParams: (params) ->
    settings = new Settings()

    localeString    = getOrElse(params, 'locale', 'en_us')
    settings.locale = localeString.replace('-', '_').toLowerCase()

    tabsString                 = getOrElse(params, 'tabs', 'bottom')
    settings.useVerticalLayout = not (tabsString is 'right')

    speedString    = getOrElse(params, 'speed', '0.0')
    settings.speed = clamp(-1, 1, parseFloatOrElse(speedString, 0.0))

    settings.workInProgress.enabled    = not params.has('disableWorkInProgress')
    settings.workInProgress.storageTag = getOrElse(params, 'storageTag', '')

    settings.events.enableDebug          = params.has('debugEvents')
    settings.events.enableIframeRelay    = params.has('relayIframeEvents')
    settings.events.iframeRelayEvents    = getOrElse(params, 'relayIframeEvents', '')
    settings.events.iframeRelayEventsTag = getOrElse(params, 'relayIframeEventsTag', '')

    settings.queries.enableDebug = params.has('debugQueries')

    settings

export default Settings
