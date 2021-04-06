# () => String
workspaceError = () ->
  'An error occurred setting up a NetTango workspace.  If this happened during normal use, then this is a bug.  If this happened while trying to load workspaces, the workspace data may have been improperly modified in some way.  See the error message for more information.'

# ({ url: String }) => String
loadFromUrlError = ({ url }) ->
  [
    'Unable to load NetTango model from the given URL.  Make sure the URL is correct, that there are no network issues, and that CORS access is permitted.'
  , ''
  , "URL: #{url}"
  ].join('<br/>')

# Map[String, (Exception) => String]
netTangoErrors = new Map([
  ['export-html',       () -> 'Unable to generate the stand-alone NetTango page.']
, ['json-apply',        () -> 'An error occurred when trying to read the given JSON for loading.  You can try to review the error and the data, fix any issues with it, and load again.']
, ['load-from-url',     loadFromUrlError]
, ['workspace-init',    workspaceError]
, ['workspace-refresh', workspaceError]
])

class NetTangoAlertDisplay extends AlertDisplay

  # (NetTangoController) => Unit
  listenForNetTangoErrors: (netTango) ->
    netTango.ractive.on('*.ntb-error', (_, source, exception) => @reportNetTangoError(source, exception))
    return

  # (String, Exception) => Unit
  reportNetTangoError: (source, exception) ->
    message = [netTangoErrors.get(source)(exception), '', exception.message].join('<br/>')
    @reportError(message)
    return

window.NetTangoAlertDisplay = NetTangoAlertDisplay
