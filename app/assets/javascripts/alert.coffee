class window.NLWAlerter

  # JQuery -> Boolean -> NLWAlerter
  constructor: (alertFrame, @isStandalone) ->
    @alertWindow    = $(alertFrame)
    @alertContainer = $(alertFrame).find("#alert-dialog").get(0)

  # String -> Boolean -> String -> Unit
  display: (title, dismissable, content) ->

    @alertWindow.find("#alert-title").text(title)
    @alertWindow.find("#alert-message").html(content)

    if @isStandalone
      $(".standalone-text").show()

    if not dismissable
      @alertWindow.find("#alert-dismiss-container").hide()
    else
      @alertWindow.find("#alert-dismiss-container").show()

    @alertWindow.css('zIndex', Math.floor(10000 + window.performance.now()))
    @alertWindow.show()

    return

  # String -> Boolean -> String -> Unit
  displayError: (content, dismissable = true, title = "Error") ->
    @display(title, dismissable, content)
    return

  # Unit -> Unit
  hide: ->
    @alertWindow.hide()
    return
