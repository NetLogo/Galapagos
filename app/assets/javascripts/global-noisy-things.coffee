class window.NLWAlerter

  # Element -> Boolean -> NLWAlerter
  constructor: (@_alertWindow, @_isStandalone) ->
    @alertContainer = @_alertWindow.querySelector("#alert-dialog")

  # String -> Boolean -> String -> Unit
  display: (title, dismissable, content) ->

    @_alertWindow.querySelector("#alert-title").innerHTML = title
    @_alertWindow.querySelector("#alert-message").innerHTML = content.replace(/(?:\n)/g, "<br>")

    if @_isStandalone
      @_alertWindow.querySelector(".standalone-text").style.display = ''

    if not dismissable
      @_alertWindow.querySelector("#alert-dismiss-container").style.display = 'none'
    else
      @_alertWindow.querySelector("#alert-dismiss-container").style.display = ''

    @_alertWindow.style.display = ''

    return

  # String -> Boolean -> String -> Unit
  displayError: (content, dismissable = true, title = "Error") ->
    @display(title, dismissable, content)
    return

  # Unit -> Unit
  hide: ->
    @_alertWindow.style.display = 'none'
    return

# (Array[String]) => Unit
window.showErrors = (errors) ->
  if errors.length > 0
    if window.nlwAlerter?
      window.nlwAlerter.displayError(errors.join('<br/>'))
    else
      alert(errors.join('\n'))
  return

# You might be thinking... don't we have the source location in the `RuntimeException`?  Why not just use that?
# Well, if the user has modified the code but not hit *Recompile* then the source location could be wrong.
# So just pass the name and use the existing code to update the location.  -Jeremy B March 2021

# (String) => false
window.jumpToProcedure = (procName) ->
  window.nlwAlerter.hide()
  window.session.widgetController.ractive.fire('jump-to-procedure', procName)
  codeTab = document.getElementById('netlogo-code-tab')
  if codeTab?
    # Something during the widget updates resets the scroll position if we do it directly.
    # So just wait a split sec and then scroll.  -Jeremy B March 2021
    scrollMe = () -> codeTab.scrollIntoView()
    window.setTimeout(scrollMe, 50)
  false

# (String, String, Array[{ name: String, location: { start: Int, end: Int } }]) => String
makeRuntimeErrorMessage = (message, primitive, frames) ->
  primError = if primitive is "" then "a primitive" else primitive.toUpperCase()
  start     = "#{message}\nerror while running #{primError}"

  messages = frames.map( (frame) ->
    switch frame.type
      when "command"  then "called by command <a href='#' onclick='return window.jumpToProcedure(\"#{frame.name}\")'>#{frame.name.toUpperCase()}</a>"
      when "reporter" then "called by reporter <a href='#' onclick='return window.jumpToProcedure(\"#{frame.name}\")'>#{frame.name.toUpperCase()}</a>"
      when "plot"     then "called by plot #{frame.name}"
      else                 "called by unknown"
  )
  stack = messages.join("\n")

  if stack isnt "" then "#{start}\n#{stack}" else start

# [T] @ (() => T) => ((Array[String]) => Unit) => T
window.handlingErrors = (f) -> (errorLog = window.showErrors) ->
  try f()
  catch ex
    if not (ex instanceof Exception.HaltInterrupt)
      message =
        if ex instanceof Exception.RuntimeException or ex instanceof Exception.ExtensionException
          makeRuntimeErrorMessage(ex.message, ex.primitive, ex.stackTrace)
        else if not (ex instanceof TypeError)
          ex.message
        else
          """A type error has occurred in the simulation engine.
             More information about these sorts of errors can be found
             <a href="https://netlogoweb.org/docs/faq#type-errors">here</a>.<br><br>
             Advanced users might find the generated error helpful, which is as follows:<br><br>
             <b>#{ex.message}</b><br><br>
             """
      errorLog([message])
      throw new Exception.HaltInterrupt
    else
      throw ex
