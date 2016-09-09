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
