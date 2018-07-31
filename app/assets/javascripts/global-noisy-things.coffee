class window.NLWAlerter

  # Element -> Boolean -> NLWAlerter
  constructor: (@_alertWindow, @_isStandalone) ->
    @alertContainer = @_alertWindow.querySelector("#alert-dialog")

  # String -> Boolean -> String -> Unit
  display: (title, dismissable, content) ->

    @_alertWindow.querySelector("#alert-title").innerHTML = title
    @_alertWindow.querySelector("#alert-message").innerHTML = content

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

# [T] @ (() => T) => () => T
window.handlingErrors = (f) -> ->
  try f()
  catch ex
    if not (ex instanceof Exception.HaltInterrupt)
      message =
        if not (ex instanceof TypeError)
          ex.message
        else
          """A type error has occurred in the simulation engine.
             More information about these sorts of errors can be found
             <a href="https://netlogoweb.org/docs/faq#type-errors">here</a>.<br><br>
             Advanced users might find the generated error helpful, which is as follows:<br><br>
             <b>#{ex.message}</b><br><br>
             """
      window.showErrors([message])
      throw new Exception.HaltInterrupt
    else
      throw ex
