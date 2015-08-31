class window.NLWAlerter
  constructor: (alertFrame, @isStandalone) ->
    @alertWindow = $(alertFrame)
    @alertContainer = $(alertFrame).find("#alert-dialog").get(0)

  display: (title, dismissable, content) ->
    @alertWindow.find("#alert-title").text(title)
    @alertWindow.find("#alert-message").html(content)
    if @isStandalone
      $(".standalone-text").show()
    if ! dismissable
      @alertWindow.find("#alert-dismiss-container").hide()
    else
      @alertWindow.find("#alert-dismiss-container").show()
    @alertWindow.show()

  displayError: (content, dismissable=true, title="Error") ->
    @display(title, dismissable, content)

  hide: () ->
    @alertWindow.hide()
