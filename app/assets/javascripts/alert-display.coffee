class AlertDisplay
  constructor: (container, isStandalone) ->
    @findConsole = (-> null)

    isLinkableProcedure = (type, name) => @isLinkableProcedure(type, name)
    isKnownProcedure    = (type, name) => @isKnownProcedure(type, name)

    @_ractive = new Ractive({
      el:       container
      template: template
      data: {
        isActive:      false        # Boolean
        isDismissable: true         # Boolean
        isStandalone:  isStandalone # Boolean
        message:       undefined    # String
        title:         undefined    # String
        frames:        undefined    # Array[StackFrame]
      }

      on: {
        show: () ->
          @set('isActive', true)
          return

        hide: () ->
          @set('isActive', false)
          return
      }

      isLinkableProcedure: isLinkableProcedure
      isKnownProcedure:    isKnownProcedure

    })

  @makeRemoteLoadErrorMessage: (url) ->
    """Unable to load NetLogo model from #{url}, please ensure:
    <ul>
      <li>That you can download the resource <a target="_blank" href="#{url}">at the link given for it.</a></li>
      <li>That the server containing the resource has
        <a target="_blank" href="https://en.wikipedia.org/wiki/Cross-origin_resource_sharing">
          Cross-Origin Resource Sharing
        </a>
        configured appropriately</li>
    </ul>
    If you have followed the above steps and are still seeing this error,
    please send an email to our <a href="mailto:bugs@ccl.northwestern.edu">"bugs" mailing list</a>
    with the following information:
    <ul>
      <li>The full URL of this page (copy and paste from address bar)</li>
      <li>Your operating system and browser version</li>
    </ul>
    """

  # (Array[Error | String]) => Array[String]
  @makeCompilerErrorMessage: (errors) ->
    contains = (s, x) -> s.indexOf(x) > -1
    errors.map( (error) ->
      if typeof(error) is 'string'
        error
      else if error.message? and
        (contains(error.message, "Couldn't find corresponding reader") or
          contains(error.message, "Models must have 12 sections"))
        errorLink = 'https://netlogoweb.org/docs/faq#model-format-error'
        "#{error.message} (see <a href='#{errorLink}'>here</a> for more information)"
      else
        if error.lineNumber? then "(Line #{error.lineNumber}) #{error.message}" else error.message
    )

  @makeBareFrameError: (frame) ->
    switch frame.type
      when 'command'  then "called by command #{frame.name.toUpperCase()}"
      when 'reporter' then "called by reporter #{frame.name.toUpperCase()}"
      when 'plot'     then "called by plot #{frame.name}"
      else                 'called by unknown'

  # (String, String) => String
  @makeRuntimeErrorMessage: (message, primitive) ->
    primError = if primitive is '' then 'a primitive' else primitive.toUpperCase()
    "#{message}\nerror while running #{primError}"

  # (String) => String
  @makeTypeErrorMessage: (message) ->
    """A type error has occurred in the simulation engine.
    More information about these sorts of errors can be found
    <a href="https://netlogoweb.org/docs/faq#type-errors">here</a>.<br><br>
    Advanced users might find the generated error helpful, which is as follows:<br><br>
    <b>#{message}</b><br><br>
    """

  # (WidgetController) => Unit
  listenForErrors: (widgetController) ->
    # we have to fetch the console as needed because it can show/hide
    @findConsole = () -> widgetController.ractive.findComponent('console')

    # If the session (and so the widgetController) are re-loaded, we need to clear the existing event binding first.
    # -Jeremy B April 2021
    @_ractive.off('jump-to-procedure')
    @_ractive.on('jump-to-procedure', (_, procName) ->
      @fire('hide')
      # You might be thinking... don't we have the source location in the `RuntimeException`?  Why not just use that
      # instead of jumping to the procedure by name?  Well, if the user has modified the code but not hit *Recompile*
      # then the source location could be wrong.  So just pass the name and find the current location.
      # -Jeremy B March 2021
      widgetController.jumpToProcedure(procName)
      false
    )

    # coffeelint: disable=max_line_length
    widgetController.ractive.on('*.nlw-notify',         (_, message)           => @reportNotification(message))
    widgetController.ractive.on('*.nlw-runtime-error',  (_, source, exception) => @reportRuntimeError(source, exception))
    widgetController.ractive.on('*.nlw-compiler-error', (_, source, errors)    => @reportCompilerErrors(source, errors))
    # coffeelint: enable=max_line_length
    return

  # (String, Exception) => Unit
  reportRuntimeError: (source, exception) ->
    if exception instanceof Exception.HaltInterrupt
      throw new Error('`HaltInterrupt` should be handled and should not be reported to users.')

    if source is 'console'
      message = if exception instanceof Exception.RuntimeException or exception instanceof Exception.ExtensionException
        start = AlertDisplay.makeRuntimeErrorMessage(exception.message, exception.primitive)
        stack = exception.stackTrace.map(AlertDisplay.makeBareFrameError).join('\n')
        if stack is '' then start else "#{start}\n#{stack}"

      else if exception instanceof TypeError
        AlertDisplay.makeTypeErrorMessage(exception.message)

      else
        exception.message

      @reportConsoleError(message)

    else
      message = if exception instanceof Exception.RuntimeException or exception instanceof Exception.ExtensionException
        AlertDisplay.makeRuntimeErrorMessage(exception.message, exception.primitive)

      else if exception instanceof TypeError
        AlertDisplay.makeTypeErrorMessage(exception.message)

      else
        exception.message

      @reportError(message, exception.stackTrace ? [])

    return

  # (String, Array[CompilerError]) => Unit
  reportCompilerErrors: (source, errors) ->
    switch source

      when 'load-from-url'
        message = AlertDisplay.makeRemoteLoadErrorMessage(errors[0])
        @_ractive.set('isDismissable', false)
        @reportError(message)

      when 'console'
        message = AlertDisplay.makeCompilerErrorMessage(errors).join('\n')
        @reportConsoleError(message)

      else
        message = AlertDisplay.makeCompilerErrorMessage(errors).join('<br/>')
        @reportError(message)

    return

  # (String, Array[StackFrame]) => Unit
  reportError: (message, frames = []) ->
    @_ractive.set('title', 'Error')
    @_ractive.set('message', message)
    @_ractive.set('frames', frames)
    @_ractive.fire('show')
    return

  # (String) => Unit
  reportConsoleError: (message) ->
    netLogoConsole = @findConsole()
    if netLogoConsole?
      message = message.replace('\n', ' ')
      netLogoConsole.appendText("ERROR: #{message}\n")
    return

  # (String) => Unit
  reportNotification: (message) ->
    @_ractive.set('title', 'NetLogo Notification')
    @_ractive.set('message', message)
    @_ractive.fire('show')
    return

  # (String, String) => Boolean
  isLinkableProcedure: (type, name) ->
    ['command', 'reporter'].includes(type)

  # (String, String) => Boolean
  isKnownProcedure: (type, name) ->
    ['command', 'reporter', 'plot'].includes(type)

template = """
<div class="dark-overlay" id="alert-overlay"{{# !isActive}} style="display: none;"{{/}}>
  <div id="alert-dialog">

    <h3 id="alert-title">{{ title }}</h3>

    <div id="alert-message" class="alert-text">
      {{{message}}}<br/>
      {{#each frames }}

        {{#if @.isLinkableProcedure(type, name) }}
          called by {{type}} <a href="/ignore" on-click=['jump-to-procedure', name]>{{ name.toUpperCase() }}</a><br/>

        {{elseif @.isKnownProcedure(type, name) }}
          called by {{type}} {{name}}<br/>

        {{else}}
          called by unknown<br/>

        {{/if}}
      {{/each}}
    </div>

    {{# isStandalone }}
    <div class="alert-text standalone-text">
      It looks like you're using NetLogo Web in standalone mode.
      <br/>
      If the above error is being caused by an unimplemented primitive, we recommend a quick visit to
      <a href="https://netlogoweb.org" target="_blank">NetLogoWeb.org</a>
      to see if the primitive has been implemented in the most up-to-date version.
    </div>
    {{/ isStandalone }}

    {{# isDismissable }}
    <div id="alert-dismiss-container">
      <button id="alert-dismiss" class="alert-button alert-separator-top" on-click="hide">
        Dismiss
      </button>
    </div>
    {{/ isDismissable }}

  </div>
</div>
"""

window.AlertDisplay = AlertDisplay
