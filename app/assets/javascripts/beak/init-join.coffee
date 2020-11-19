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

protocolObj = { protocolVersion: "0.0.1" }

# (Sting, Object[Any]) => Unit
sendHNWPayload = (type, payload) ->
  parent.postMessage({ type: "relay", payload: Object.assign({}, payload, { token, type }, protocolObj) }, "*")
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

  myRole         = undefined
  myUsername     = undefined
  cachedDrawings = {}

  window.addEventListener("message", (e) ->

    switch e.data.type
      when "hnw-load-interface"

        token = e.data.token

        myRole     = e.data.role.name
        myUsername = e.data.username

        loadHNWModel(e.data.role, e.data.view)

        for widget in e.data.role.widgets
          switch widget.type
            when "hnwInputBox", "hnwSlider"
              world.observer.setGlobal(widget.variable, widget.default)
            when "hnwChooser"
              world.observer.setGlobal(widget.variable, widget.choices[widget.currentChoice])
            when "hnwSwitch"
              world.observer.setGlobal(widget.variable, widget.on)

        exiles =
          [ document.querySelector('.netlogo-header')
          , document.querySelector('.netlogo-display-horizontal')
          , document.querySelector('.netlogo-speed-slider')
          , document.querySelector('.netlogo-tab-area')
          ]

        exiles.forEach((n) -> n.style.display = "none")

        vc = session.widgetController.viewController

        onClick =
          ->
            obj = { subtype: "click", xcor: vc.mouseXcor(), ycor: vc.mouseYcor() }
            sendHNWWidgetMessage('view', obj)

        vc.view.visibleCanvas.addEventListener('click', onClick)

        if token isnt "invalid token"
          sendHNWMessage("interface-loaded", null)

      when "nlw-update-model-state"
        session.widgetController.setCode(e.data.codeTabContents)
      when "nlw-request-model-state"
        update = session.getModelState(myRole)
        e.source.postMessage({ update, type: "nlw-state-update", sequenceNum: -1 }, "*")
      when "nlw-request-view"
        base64 = session.widgetController.viewController.repaint()
        base64 = session.widgetController.viewController.view.visibleCanvas.toDataURL("image/png")
        e.source.postMessage({ base64, type: "nlw-view" }, "*")
      when "nlw-subscribe-to-updates"
        session.subscribe(e.source)

      when "hnw-are-you-ready-for-interface"
        e.source.postMessage({ type: "yes-i-am-ready-for-interface" }, "*")

      when "nlw-state-update", "nlw-apply-update"

        if session?

          { widgetUpdates, monitorUpdates, plotUpdates, ticks, viewUpdate } = e.data.update

          if ticks?
            world.ticker.reset()
            world.ticker.importTicks(ticks)

          if widgetUpdates?
            session.widgetController.applyWidgetUpdates(widgetUpdates)

          if plotUpdates?
            session.widgetController.applyPlotUpdates(plotUpdates)

          if monitorUpdates?
            session.widgetController.applyMonitorUpdates(monitorUpdates)

          if viewUpdate?

            vc = session.widgetController.viewController

            { turtles = {}, patches = {}, links = {}, drawingEvents = [] } = viewUpdate
            goodTurtles = -> Object.entries(turtles).every(([key, t]) -> t.id? or t.WHO? or t.who?                               or vc.model.turtles[key]?)
            goodLinks   = -> Object.entries(links  ).every(([key, l]) -> l.id? or (l.END1? and l.END2?) or (l.end1? and l.end2?) or vc.model.links  [key]?)
            goodPatches = -> Object.entries(patches).every(([key, p]) -> (p.pxcor? and p.pycor?)                                 or vc.model.patches[key]?)

            allAgentsAreKnown =
              ((not turtles?) or goodTurtles()) and
              ((not   links?) or goodLinks()  ) and
              ((not patches?) or goodPatches())

            if allAgentsAreKnown

              checkIsMajorDrawingEvent =
                (x) ->
                  x.type in ["import-drawing-raincheck", "import-drawing", "clear-drawing"]

              desWithIndices = drawingEvents.map((de, i) -> [de, i])

              lastDrawingIndex =
                desWithIndices.reduce(((acc, [de, i]) -> if checkIsMajorDrawingEvent(de) then i else acc), -1)

              realDrawings =
                drawingEvents.filter(
                  (de) ->
                    (not checkIsMajorDrawingEvent(de)) or (de is drawingEvents[lastDrawingIndex])
                )

              # Side-effectful munging to avoid blasting the host with 10 image requests on startup --JAB (11/19/20)
              trueDrawings =
                realDrawings.reduce(
                  (acc, x) ->
                    switch x.type
                      when "import-drawing"
                        cachedDrawings[x.hash] = x.imageBase64
                        acc.concat([x])
                      when "import-drawing-raincheck"
                        if cachedDrawings[x.hash]?
                          acc.concat({ type: "import-drawing", imageBase64: cachedDrawings[x.hash] })
                        else
                          sendHNWPayload("hnw-cash-raincheck", { id: x.hash })
                          acc
                      else
                        acc.concat([x])
                , [])

              trueUpdate = Object.assign(viewUpdate, { drawingEvents: trueDrawings })
              vc.applyUpdate(trueUpdate)
              vc.repaint()

            else

              baddie = undefined

              badTurtle    = -> Object.entries(turtles).find(([key, t]) -> not (t.id? or t.WHO? or t.who?                               or vc.model.turtles[key]?))
              if turtles? and badTurtle()?
                baddie = ["turtle", badTurtle]
              else
                badLink    = -> Object.entries(links  ).find(([key, l]) -> not (l.id? or (l.END1? and l.END2?) or (l.end1? and l.end2?) or vc.model.links  [key]?))
                if links? and badLink()?
                  baddie = ["link", badLink]
                else
                  badPatch = -> Object.entries(patches).find(([key, p]) -> not ((p.pxcor? and p.pycor?)                                 or vc.model.patches[key]?))
                  if patches? and badPatch()?
                    baddie = ["patch", badPatch]

              if baddie?
                parent.postMessage({
                  type:      "hnw-fatal-error"
                , subtype:   "unknown-agent"
                , agentType: baddie[0]
                , agentID:   baddie[1][0]
                }, "*")
              else
                console.warn("Somehow, not all agents were known, but we couldn't extract a baddie...?")

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
