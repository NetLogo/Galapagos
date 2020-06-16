loadingOverlay  = document.getElementById("loading-overlay")
modelContainer  = document.querySelector("#netlogo-model-container")
nlogoScript     = document.querySelector("#nlogo-code")

activeContainer = loadingOverlay

session = undefined
token   = undefined # String

isStandaloneHTML = nlogoScript.textContent.length > 0

window.nlwAlerter = new NLWAlerter(document.getElementById("alert-overlay"), isStandaloneHTML)

window.isHNWJoiner = true

# (String) => String
genPageTitle = (modelTitle) ->
  if modelTitle? and modelTitle isnt ""
    "NetLogo Web: #{modelTitle}"
  else
    "NetLogo Web"

# (Session) => Unit
openSession = (s) ->
  session         = s
  document.title  = genPageTitle(session.modelTitle())
  activeContainer = modelContainer
  session.startLoop()
  return

# (String) => Unit
displayError = (error) ->
  # in the case where we're still loading the model, we have to
  # post an error that cannot be dismissed, as well as ensuring that
  # the frame we're in matches the size of the error on display.
  if activeContainer is loadingOverlay
    window.nlwAlerter.displayError(error, false)
    activeContainer = window.nlwAlerter.alertContainer
  else
    window.nlwAlerter.displayError(error)
  return

# (Role, View) => Unit
loadHNWModel = (role, view) ->
  session?.teardown()
  window.nlwAlerter.hide()
  activeContainer = loadingOverlay
  Tortoise.loadHubNetWeb(modelContainer, role, view, openSession)
  session.subscribe(parent)
  return

# (Sting, Object[Any]) => Unit
sendHNWPayload = (type, payload) ->
  parent.postMessage({ type: "relay", payload: Object.assign({}, payload, { token, type }) }, "*")
  return

# (String, Any) => Unit
sendHNWMessage = (type, message) ->
  sendHNWPayload(type, { message })
  return

# (String, Any) => Unit
window.sendHNWWidgetMessage = (type, message) ->
  sendHNWPayload("hnw-widget-message", { data: { type, message } })
  return

# () -> Unit
setUpEventListeners = ->

  myRole = undefined

  window.addEventListener("message", (e) ->

    switch e.data.type
      when "hnw-load-interface"

        token = e.data.token

        myRole = e.data.role.name

        loadHNWModel(e.data.role, e.data.view)

        for widget in e.data.role.widgets
          if widget.type in ["hnwChooser", "hnwInputBox", "hnwSlider"]
            world.observer.setGlobal(widget.variable, widget.default)
          else if widget.type is "hnwSwitch"
            world.observer.setGlobal(widget.variable, widget.on)

        exiles =
          [ document.querySelector('.netlogo-header')
          , document.querySelector('.netlogo-display-horizontal')
          , document.querySelector('.netlogo-speed-slider')
          , document.querySelector('.netlogo-tab-area')
          ]

        exiles.forEach((n) -> n.style.display = "none")

        sendHNWMessage("interface-loaded", null)

      when "nlw-update-model-state"
        session.widgetController.setCode(e.data.codeTabContents)
      when "nlw-request-model-state"
        update = session.getModelState(myRole)
        e.source.postMessage({ update, type: "nlw-state-update" }, "*")
      when "nlw-request-view"
        base64 = session.widgetController.viewController.view.visibleCanvas.toDataURL("image/png")
        e.source.postMessage({ base64, type: "nlw-view" }, "*")
      when "nlw-subscribe-to-updates"
        session.subscribe(e.source)
      when "nlw-state-update", "nlw-apply-update"

        if session?

          { widgetUpdates, monitorUpdates, plotUpdates, ticks, viewUpdates } = e.data.update

          world.ticker.reset()
          world.ticker.importTicks(ticks)

          session.widgetController.applyWidgetUpdates(widgetUpdates)
          session.widgetController.applyPlotUpdates(plotUpdates)
          session.widgetController.applyMonitorUpdates(monitorUpdates)

          vc = session.widgetController.viewController
          viewUpdates.forEach((vu) -> vc.applyUpdate(vu))
          vc.repaint()

      when "hnw-widget-update"
        if (e.data.event.type is "ticksStarted")
          session.widgetController.ractive.set('ticksStarted', e.data.event.value)
        else
          console.warn("Unknown HNW widget update type")

  )

  return

# () => Unit
handleFrameResize = ->

  if parent isnt window

    width  = ""
    height = ""

    onInterval =
      ->
        if (activeContainer.offsetWidth  isnt width or
            activeContainer.offsetHeight isnt height or
            (session? and document.title isnt genPageTitle(session.modelTitle())))

          if session?
            document.title = genPageTitle(session.modelTitle())

          width  = activeContainer.offsetWidth
          height = activeContainer.offsetHeight

          parent.postMessage({
            width:  activeContainer.offsetWidth,
            height: activeContainer.offsetHeight,
            title:  document.title,
            type:   "hnw-resize"
          }, "*")

    window.setInterval(onInterval, 200)

  return

setUpEventListeners()
handleFrameResize()
