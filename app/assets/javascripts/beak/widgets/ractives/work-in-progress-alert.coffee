CACHE_ALERT_DEFAULT_DISPLAY_TIME = 20

createWorkInProgressAlert = (sourceType) ->
  shortMessage = "This model has been loaded with previous work in progress found in your cache."
  sourceMessage = switch sourceType
    when 'url'
      'model from the link'
    when 'disk'
      'model from the uploaded file'
    when 'new'
      'new blank model'
    when 'script-element'
      'model from the page'
    else
      'model'
  revertButton = """the <a on-click="revert-wip" href="javascript:void(0)">Revert to Original</a> button"""
  message = """#{shortMessage}
    To reload the unmodified #{sourceMessage},
    press #{revertButton}."""
  {
    id:      "work-in-progress-notice-#{Date.now()}",
    message: message,
    timeout: CACHE_ALERT_DEFAULT_DISPLAY_TIME * 1000
  }

export default createWorkInProgressAlert
