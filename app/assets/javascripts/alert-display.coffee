{ isSomething, toArray } = tortoise_require('brazier/maybe')

contains = (s, x) -> s.indexOf(x) > -1

class AlertDisplay
  constructor: (container, isStandalone) ->
    @appendToConsole = (-> null)

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
        show: (_, title, message, frames) ->
          if @get('isActive')
            @set('title', "#{@get('title')} / #{title}")
            @set('message', "#{message}<br/><br/>Next message: #{@get('message')}")
          else
            @set('title', title)
            @set('message', message)
            @set('frames', frames)
            @set('isActive', true)
          return

        hide: () ->
          @set('isDismissable', true)
          @set('isActive', false)
          return

        '*.copy-message': (_) ->
          message = @find('#alert-message')
          navigator.clipboard.writeText(message?.innerText)
          return

      }

      isLinkableProcedure: isLinkableProcedure
      isKnownProcedure:    isKnownProcedure

    })

  # This method is for scenarios where an unexpected error occured trying to initialize the basic model/simulation code.
  # So we don't assume even Ractive or other libraries are usable, we just try some basic HTML/DOM changes to show the
  # user the error message.  -Jeremy B April 2024

  # (Exception) => Unit
  @showEarlyInitFailure: (ex) ->
    alertBox = document.getElementById('alert-container')

    alertOverlay = document.createElement('div')
    alertOverlay.classList.add('dark-overlay')
    alertOverlay.classList.add('alert-overlay')
    alertBox.appendChild(alertOverlay)

    alertDialog = document.createElement('div')
    alertDialog.id = 'alert-dialog'
    alertDialog.classList.add('alert-dialog')
    alertOverlay.appendChild(alertDialog)

    alertTitle = document.createElement('h3')
    alertTitle.id = 'alert-title'
    alertTitle.innerText = 'Simulation Initialization Error'
    alertDialog.appendChild(alertTitle)

    alertText = document.createElement('div')
    alertText.id = 'alert-message'
    alertText.classList.add('alert-text')
    # coffeelint: disable=max_line_length
    alertText.innerText = """An error has occured while NetLogo Web was initializing the simulaton engine and view.  You can try reloading to see if this resolves the problem.

    If you need additional assistance you can email bugs@ccl.northwestern.edu.  In order to be able to help, please provide us with 1) the error below 2) the full URL of this page from the address bar 3) your web browser (Chrome, Firefox, Safari, Edge) and 4) your operating system (macOS, Windows, Chromebook, Linux).

      #{ex.message}

      Stack: #{ex.stack}
      """
    # coffeelint: enable=max_line_length
    alertDialog.appendChild(alertText)

    loadingOverlay = document.getElementById('loading-overlay')
    loadingOverlay.style = 'display: none;'
    return

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

  # (String, String, Maybe[Int], Maybe[Int], String) => String
  @makeBareRuntimeErrorMessage: (message, primitive, sourceStart, sourceEnd, code) ->
    prim     = if primitive is '' then 'a primitive' else primitive.toUpperCase()
    location = if not (isSomething(sourceStart)) then "" else
      start = toArray(sourceStart)[0]
      line  = code.slice(0, start).split("\n").length
      " on line #{line}"
    "#{message}\nerror while running #{prim}#{location}"

  # (String, String, String) => String
  @makeButtonRuntimeErrorMessage: (message, primitive, code) ->
    prim = if primitive is '' then 'a primitive' else primitive.toUpperCase()
    "#{message}\nerror while running #{prim} in button \"#{code}\""

  # (String, String, Maybe[Int], Maybe[Int]) => String
  @makeLinkedRuntimeErrorMessage: (message, primitive, sourceStart, sourceEnd) ->
    prim       = if primitive is '' then 'a primitive' else primitive.toUpperCase()
    linkedPrim = if not (isSomething(sourceStart) and isSomething(sourceEnd)) then "running #{prim}" else
      start       = toArray(sourceStart)[0]
      end         = toArray(sourceEnd)[0]
      onclickCode = "this.parentElement._ractive.proxy.ractive.fire(\"jump-to-code\", #{start}, #{end}); return false;"
      "<a href='/ignore' onclick='#{onclickCode}'>running #{prim}</a>"
    "#{message}\nerror while #{linkedPrim}"

  # (String) => String
  @makeTypeErrorMessage: (message) ->
    """A type error has occurred in the simulation engine.
    More information about these sorts of errors can be found
    <a href="https://netlogoweb.org/docs/faq#type-errors">here</a>.<br><br>
    Advanced users might find the generated error helpful, which is as follows:<br><br>
    <b>#{message}</b><br><br>
    """

  # () => String
  @makeProtocolErrorMessage: (badHref, newModelUrl, newHref) ->
    newLink = if not newHref? then newModelUrl else
      """<a href="#{newHref}">#{newModelUrl}</a>"""

    """<p>The linked model protocol is insecure (HTTP) but the NetLogo Web page is secure (HTTPS),
    so the model cannot be loaded as specified.</p>
    <p>You can try to load the model securely by changing to the below link, but it assumes the default
    secure port for the model's host, which may not be correct.</p>
    <p>Original model link: #{badHref}</p>
    <p>New model link to try: #{newLink}</p>
    <ul>
    """

  # (WidgetController) => Unit
  setWidgetController: (widgetController) ->

    # we have to fetch the console as needed because it can show/hide
    @appendToConsole =
      (msg) ->
        wcRactive = widgetController.ractive
        wcRactive.set('consoleOutput', wcRactive.get('consoleOutput') + msg)

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
    @_ractive.off('jump-to-code')
    @_ractive.on('jump-to-code', (_, sourceStart, sourceEnd) ->
      @fire('hide')
      widgetController.jumpToCode(sourceStart, sourceEnd)
      false
    )

    return

  # (CommonEventArgs, { messages: Array[String] }) => Unit
  'extension-error': (_, {messages}) ->
    @reportError(messages.join('<br/>'))
    return

  # (CommonEventArgs, { source: String, exception: Exception, code: String | undefined }) => Unit
  'runtime-error': (_, {source, exception, code}) ->
    if exception instanceof Exception.HaltInterrupt
      throw new Error('`HaltInterrupt` should be handled and should not be reported to users.')

    if source is 'console'
      message = if exception instanceof Exception.RuntimeException
        start = AlertDisplay.makeBareRuntimeErrorMessage(
          exception.message
        , exception.primitive
        , exception.sourceStart
        , exception.sourceEnd
        , code
        )
        stack = exception.stackTrace.map(AlertDisplay.makeBareFrameError).join('\n')
        if stack is '' then start else "#{start}\n#{stack}"

      else if exception instanceof TypeError
        AlertDisplay.makeTypeErrorMessage(exception.message)

      else
        exception.message

      @reportConsoleError(message)

    else
      message = if exception instanceof Exception.RuntimeException
        if source is 'button' and exception.stackTrace.length is 0
          AlertDisplay.makeButtonRuntimeErrorMessage(exception.message, exception.primitive, code)

        else
          AlertDisplay.makeLinkedRuntimeErrorMessage(
            exception.message
          , exception.primitive
          , exception.sourceStart
          , exception.sourceEnd
          )

      else if exception instanceof TypeError
        AlertDisplay.makeTypeErrorMessage(exception.message)

      else
        exception.message

      @reportError(message, exception.stackTrace ? [])

    return

  # (CommonEventArgs, { source: String, modelSourceType: String,
  #    modelCode: String, errors: Array[CompilerError] }) => Unit
  'compiler-error': (_, { source, modelSourceType, modelCode, errors }) ->

    stuffIntoTextBox = (msg) ->
      """<textarea readonly style="width: 100%; height: 400px;">#{msg}</textarea>"""

    switch source

      when 'load-from-url'
        message = AlertDisplay.makeRemoteLoadErrorMessage(errors[0])
        @_ractive.set('isDismissable', false)
        @reportError(message)

      when 'console'
        message = AlertDisplay.makeCompilerErrorMessage(errors).join('\n')
        @reportConsoleError(message)

      when 'compile-fatal'
        @_ractive.set('isDismissable', false)
        rawMessage = AlertDisplay.makeCompilerErrorMessage(errors).join('<br/>')
        messageBits =
          if contains(rawMessage, "Models must have 12 sections, this had 1")
            [
              """There was an error compiling the model's code.  The given model was not a
              NetLogo 7 <code>.nlogox</code> file or a NetLogo 6.4 <code>.nlogo</code> file.""",
              (switch modelSourceType
                when 'url'
                  """The linked model was fetched without error, but the contents are incorrect.
                  Check your link to make sure it is to the correct model."""
                when 'disk'
                  """Check that you selected the correct file to upload."""
                when 'script-element'
                  """If you made manual changes to the embedded model, make sure they are valid
                  or try re-exporting your model as an HTML file."""
                else
                  "Unrecognized model source type, something odd is going on."),
              "The model contents that failed to compile are given below.",
              stuffIntoTextBox(modelCode)
            ]
          else
            [
              """There was an error compiling the model's code. If you uploaded a model, make
              sure it is a working NetLogo 7 <code>.nlogox</code> file or NetLogo 6.4
              <code>.nlogo</code> file.""",
              rawMessage,
              "The model contents that failed to compile are given below.",
              stuffIntoTextBox(modelCode)
            ]
        @reportError(messageBits.join("<br/><br/>"))

      else
        rawMessage = AlertDisplay.makeCompilerErrorMessage(errors).join('<br/>')
        message = if not @_ractive.get('isActive') then rawMessage else
          """There was an error compiling the model's code:<br/><br/>
          #{rawMessage}<br/><br/>
          The below errors were generated by the widgets, but they may be
          caused by the above compilation issues in the model's code."""
        @reportError(message)

    return

  # (URL, String) => Unit
  reportProtocolError: (badUrl, newModelUrl, newHref) ->
    message = AlertDisplay.makeProtocolErrorMessage(badUrl, newModelUrl, newHref)
    @_ractive.set('isDismissable', false)
    @reportError(message)

  # () => Unit
  hide: () ->
    @_ractive.fire('hide')
    return

  # (String, Array[StackFrame]) => Unit
  reportError: (message, frames = []) ->
    @show('Error', message, frames)
    return

  # (String) => Unit
  reportConsoleError: (message) ->
    fullMessage = "ERROR: #{message.replace('\n', ' ')}\n"
    @appendToConsole(fullMessage)
    return

  'notify-user': (_1, {message}) ->
    @reportNotification(message)
    return

  # (String) => Unit
  reportNotification: (message) ->
    @show('NetLogo Notification', message, [])
    return

  show: (title, message, frames) ->
    @_ractive.fire('show', title, message, frames)
    return

  # (String, String) => Boolean
  isLinkableProcedure: (type, name) ->
    ['command', 'reporter'].includes(type)

  # (String, String) => Boolean
  isKnownProcedure: (type, name) ->
    ['command', 'reporter', 'plot'].includes(type)

# coffeelint: disable=max_line_length
template = """
<div class="dark-overlay alert-overlay"{{# !isActive}} style="display: none;"{{/}}>

  {{# isActive}}
  <div class="alert-dialog" id="alert-dialog">

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

    <div id="alert-dismiss-container">
      <input id="alert-copy" type="button" class="alert-button" on-click="copy-message" value="Copy Message to Clipboard" />
      {{# isDismissable }}
      <input id="alert-dismiss" type="button" class="alert-button alert-separator-top" on-click="hide" value="Dismiss" />
      {{/ isDismissable }}
    </div>

  </div>
  {{/ isActive }}

</div>
"""
# coffeelint: enable=max_line_length

export default AlertDisplay
