import AlertDisplay from "/alert-display.js"

# coffeelint: disable=max_line_length
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
  ['export-html',          () -> 'Unable to generate the stand-alone NetTango page.']
, ['export-nlogo',         () -> 'Unable to get NetLogo model code for NetTango project export.']
, ['json-apply',           () -> 'An error occurred when trying to read the given JSON for loading.  You can try to review the error and the data, fix any issues with it, and load again.']
, ['parse-project-json',   () -> 'The JSON data in the project file could not be parsed.  Review the error below and make sure it is a valid NetTango Web project file.']
, ['load-from-url',        loadFromUrlError]
, ['load-library-json',    () -> 'Unable to load the NetTango library file.  Are you running on netlogoweb.org?']
, ['attribute-change',     () -> 'An error occured when trying to update a block attribute value.  Check the error below and the generated NetLogo Code for your model to see if anything looks strange, but this probably indicates a bug in NetTango Web.']
, ['recompile-procedures', () -> 'The blocks code contains an error and cannot be compiled.  You can try undoing the last block change or checking the error message to try to locate the problem.']
, ['workspace-init',       workspaceError]
, ['workspace-refresh',    workspaceError]
])
# coffeelint: enable=max_line_length

makeRecompileOverlay = (container) ->
  ractive = new Ractive({
    el:       container
    template: '<button class="ntb-button" on-click="recompile">Recompile</button>'
    show:     () -> container.style.display = 'flex'
    hide:     () -> container.style.display = 'none'
  })
  container.addEventListener('click', () -> ractive.fire('recompile') )
  ractive

class NetTangoAlertDisplay extends AlertDisplay

  constructor: (container, isStandalone, @recompileContainer) ->
    super(container, isStandalone)
    @recompileOverlay = makeRecompileOverlay(@recompileContainer)

  # (WidgetController) => Unit
  listenForErrors: (widgetController) ->
    super(widgetController)
    @recompileOverlay.on('*.recompile', (_) ->
      widgetController.ractive.fire('recompile', () => @hide())
      return
    )
    return

  # (NetTangoController) => Unit
  listenForNetTangoErrors: (netTango) ->
    @netTango = netTango
    netTango.ractive.on('*.ntb-error', (_, source, exception) => @reportNetTangoError(source, exception))
    return

  # (String, Exception) => Unit
  reportNetTangoError: (source, exception) ->
    message = if not netTangoErrors.has(source)
      'Generic NetTango error occured.'
    else
      netTangoErrors.get(source)(exception)

    @reportError([message, '', exception.message].join('<br/>'))
    return

  # (String, CompilerError) => Boolean
  isNetTangoError: (netLogoCode, error) ->
    if error.start? and error.start > netLogoCode.length
      true
    else if error.lineNumber? and error.lineNumber > netLogoCode.split('\n').length
      true
    else
      false

  # (String, Array[CompilerError]) => Unit
  reportCompilerErrors: (source, errors) ->
    switch source
      when 'compile-fatal'
        message = AlertDisplay.makeCompilerErrorMessage(errors).join('<br/>')
        @reportError(message)

      when 'compile-recoverable'
        netLogoCode = @netTango.getNetLogoCode()
        if @isNetTangoError(netLogoCode, errors[0])
          @recompileOverlay.show()
          @reportNetTangoError('recompile-procedures', errors[0])
        else
          message = AlertDisplay.makeCompilerErrorMessage(errors).join('<br/>')
          @reportError(message)

      when 'recompile-procedures'
        @recompileOverlay.show()
        @reportNetTangoError('recompile-procedures', errors[0])

      else
        super.reportCompilerErrors(source, errors)

    return

  # (String, String) => Boolean
  isLinkableProcedure: (type, name) ->
    super.isLinkableProcedure(type, name) and not @isNetTangoProcedure(name) and @isCodeTabAvailable()

  # (String) => Boolean
  isNetTangoProcedure: (name) ->
    procedures = @netTango.getProcedures()
    procedures.includes(name.toUpperCase())

  # () => Boolean
  isCodeTabAvailable: () ->
    tabOptions = @netTango.builder.get('tabOptions')
    not @netTango.playMode or not tabOptions.codeTab?.checked

export default NetTangoAlertDisplay
