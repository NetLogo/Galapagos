CACHE_ALERT_DEFAULT_DISPLAY_TIME = 20

# (String) => RactiveToastProps
createLoadChangesAlert = (sourceType) ->
  loadLink     = """<a on-click="load-wip" href="javascript:void(0)">Load Changes</a>"""
  settingsNote = if sourceType is 'script-element'
    ''
  else
    ' You can disable this notice in NetLogo Web settings.'
  message = """Unsaved changes to this model were found in your browser's cache.
    Click #{loadLink} to apply them, or dismiss to keep the model as linked.#{settingsNote}"""
  {
    id:      "load-changes-notice-#{Date.now()}",
    message: message,
    timeout: CACHE_ALERT_DEFAULT_DISPLAY_TIME * 1000
  }

export default createLoadChangesAlert
