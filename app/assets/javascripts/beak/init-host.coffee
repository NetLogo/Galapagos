loadingOverlay  = document.getElementById("loading-overlay")
modelContainer  = document.querySelector("#netlogo-model-container")
nlogoScript     = document.querySelector("#nlogo-code")

activeContainer = loadingOverlay

session = undefined

isStandaloneHTML = nlogoScript.textContent.length > 0

window.nlwAlerter = new NLWAlerter(document.getElementById("alert-overlay"), isStandaloneHTML)

window.isHNWHost = true

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

# (String, String) => Unit
loadModel = (nlogo, path) ->
  session?.teardown()
  window.nlwAlerter.hide()
  activeContainer = loadingOverlay
  Tortoise.fromNlogo(nlogo, modelContainer, path, openSession, displayError)
  return

# () => Unit
loadInitialModel = ->
  if nlogoScript.textContent.length > 0
    Tortoise.fromNlogo(nlogoScript.textContent,
                       modelContainer,
                       nlogoScript.dataset.filename,
                       openSession,
                       displayError)
  else if window.location.search.length > 0

    reducer =
      (acc, pair) ->
        acc[pair[0]] = pair[1]
        acc

    query    = window.location.search.slice(1)
    pairs    = query.split(/&(?=\w+=)/).map((x) -> x.split('='))
    paramObj = pairs.reduce(reducer, {})

    url       = paramObj.url ? query
    modelName = if paramObj.name? then decodeURI(paramObj.name) else undefined

    Tortoise.fromURL(url, modelName, modelContainer, openSession, displayError)

  else
    loadModel(exports.newModel, "NewModel")

  return

protocolObj = { protocolVersion: "0.0.1" }

# (Sting, Object[Any]) => Unit
broadcastHNWPayload = (type, payload) ->
  truePayload = Object.assign({}, payload, { type }, protocolObj)
  parent.postMessage({ type: "relay", payload: truePayload }, "*")
  return

# (String, Sting, Object[Any]) => Unit
window.narrowcastHNWPayload = (uuid, type, payload) ->
  truePayload = Object.assign({}, payload, { type }, protocolObj)
  parent.postMessage({ type: "relay", recipient: uuid, payload: truePayload }, "*")
  return

# () -> Unit
setUpEventListeners = ->

  window.clients = {}

  roles = {}

  window.addEventListener("message", (e) ->

    switch e.data.type
      when "nlw-load-model"
        loadModel(e.data.nlogo, e.data.path)
      when "nlw-open-new"
        loadModel(exports.newModel, "NewModel")
      when "nlw-update-model-state"
        session.widgetController.setCode(e.data.codeTabContents)
      when "run-baby-behaviorspace"
        parcel   = { type: "baby-behaviorspace-results", id: e.data.id, data: results }
        reaction = (results) -> e.source.postMessage(parcel, "*")
        session.asyncRunBabyBehaviorSpace(e.data.config, reaction)
      when "nlw-request-model-state"
        update = session.getModelState("")
        e.source.postMessage({ update, type: "nlw-state-update", sequenceNum: -1 }, "*")
      when "nlw-request-view"
        base64 = session.widgetController.viewController.repaint()
        base64 = session.widgetController.viewController.view.visibleCanvas.toDataURL("image/png")
        e.source.postMessage({ base64, type: "nlw-view" }, "*")
      when "nlw-subscribe-to-updates"
        if not window.clients[e.data.uuid]?
          window.clients[e.data.uuid] = {}
        window.clients[e.data.uuid].window = e.source
        session.subscribeWithID(e.source, e.data.uuid)
      when "nlw-state-update", "nlw-apply-update"

        { widgetUpdates, monitorUpdates, plotUpdates, ticks, viewUpdates } = e.data.update

        if ticks?
          world.ticker.reset()
          world.ticker.importTicks(ticks)

        if widgetUpdates?
          session.widgetController.applyWidgetUpdates(widgetUpdates)

        if plotUpdates?
          session.widgetController.applyPlotUpdates(plotUpdates)

        if viewUpdates?
          vc = session.widgetController.viewController
          viewUpdates.forEach((vu) -> vc.applyUpdate(vu))
          vc.repaint()

      when "relay"
        window.postMessage(e.data.payload, "*")

      when "hnw-fatal-error"
        window.parent.postMessage(e.data, "*")

      when "hnw-request-initial-state"

        viewState = session.widgetController.widgets().find(({ type }) -> type is 'view')
        role      = roles[e.data.roleName]

        session.subscribeWithID(null, e.data.token)

        username = e.data.username
        who      = world.turtleManager.peekNextID()

        window.clients[e.data.token] =
          { roleName: role.name
          , username
          , who
          , window: null
          }

        # NOTE
        if role.onConnect?
          procedures[role.onConnect.toUpperCase()]()
          world.turtleManager.getTurtle(who).ask((-> SelfManager.self().setVariable("__hnw-username", username)), false)
          session.updateWithoutRendering(e.data.token)

        # NOTE
        monitorUpdates = session.monitorsFor(e.data.token)
        state          = Object.assign({}, session.getModelState(""), { monitorUpdates })

        e.source.postMessage({ token: e.data.token, role, state, viewState, type: "hnw-initial-state" }, "*")

      when "hnw-resize"

        isValid = (x) -> x?

        height = e.data.height
        width  = e.data.width
        title  = e.data.title

        if [height, width, title].every(isValid)
          elem           = document.getElementById("hnw-join-frame")
          elem.width     = width
          elem.height    = height
          document.title = title

      when "hnw-widget-message"

        token  = e.data.token
        client = window.clients[token]
        role   = roles[client.roleName]
        who    = client.who

        switch e.data.data.type
          when "button"
            procedure = procedures[e.data.data.message.toUpperCase()]
            if role.isSpectator
              procedure()
            else
              world.turtleManager.getTurtle(who).ask(procedure, false)
          when "slider", "switch", "chooser", "inputBox"
            { varName, value } = JSON.parse(e.data.data.message)
            if role.isSpectator
              mangledName = "__hnw_#{role.name}_#{varName}"
              world.observer.setGlobal(mangledName, value)
            else
              world.turtleManager.getTurtle(who).ask((-> SelfManager.self().setVariable(varName, value)), false)
          when "view"
            message = e.data.data.message
            switch message.subtype
              when "click"
                if role.onCursorClick?
                  thunk = (-> procedures[role.onCursorClick.toUpperCase()](message.xcor, message.ycor))
                  world.turtleManager.getTurtle(who).ask(thunk, false)
              else
                console.warn("Unknown HNW View event subtype")
          else
            console.warn("Unknown HNW widget event type")

      when "hnw-become-oracle"

        loadModel(e.data.nlogo, "Jason's Experimental Funland")

        header = document.querySelector('.netlogo-header')

        exiles =
          [ header.querySelector('.netlogo-subheader')
          , header.querySelector('.flex-column')
          , document.querySelector('.netlogo-model-title')
          , document.querySelector('.netlogo-toggle-container')
          ]

        # Spectator Mode!

        exiles.forEach((n) -> n.style.display = "none")

        wContainer = document.querySelector('.netlogo-widget-container')
        parent     = wContainer.parentNode

        flexbox                     = document.createElement("div")
        flexbox.style.display       = "flex"
        flexbox.style.flexDirection = "row"

        parent.replaceChild(flexbox, wContainer)

        baseView = session.widgetController.widgets().find(({ type }) -> type is 'view')

        tabAreaElem = document.querySelector(".netlogo-tab-area")
        taeParent   = tabAreaElem.parentNode

        setupButton           = document.createElement("button")
        setupButton.innerHTML = "setup"
        setupButton.id        = "hnw-setup-button"
        setupButton.addEventListener('click', -> procedures.SETUP())

        goCheckbox           = document.createElement("label")
        goCheckbox.innerHTML = "go<input id='hnw-go' type='checkbox'>"

        taeParent.insertBefore(setupButton, tabAreaElem)
        taeParent.insertBefore(goCheckbox , tabAreaElem)

        genUUID = ->

          replacer =
            (c) ->
              r = Math.random() * 16 | 0
              v = if c == 'x' then r else (r & 0x3 | 0x8)
              v.toString(16)

          'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, replacer)

        roles = {}
        e.data.roles.forEach((role) -> roles[role.name] = role)

        for role in roles
          for widget in role.widgets
            if widget.type is "hnwMonitor"
              monitor = widget
              safely = (f) -> (x) ->
                try f(x)
                catch ex
                  "N/A"
              func =
                switch monitor.reporterStyle
                  when "global-var"
                    do (monitor) -> safely(-> world.observer.getGlobal(monitor.source))
                  when "procedure"
                    do (monitor) -> safely(-> procedures[monitor.source.toUpperCase()]())
                  when "turtle-var"
                    plural = world.breedManager.getSingular(role.name).name
                    do (monitor) -> safely((who) -> world.turtleManager.getTurtleOfBreed(plural, who).getVariable(monitor.source))
                  when "turtle-procedure"
                    plural = world.breedManager.getSingular(role.name).name
                    do (monitor) -> safely((who) -> world.turtleManager.getTurtleOfBreed(plural, who).projectionBy(procedures[monitor.source.toUpperCase()]))
                  else
                    console.log("We got '#{monitor.reporterStyle}'?")
              session.registerMonitorFunc(role.name, monitor.display, func)

        supervisorFrame     = document.createElement("iframe")
        supervisorFrame.id  = "hnw-join-frame"
        supervisorFrame.src = "/hnw-join"

        supervisorFrame.style.border = "3px solid red"
        supervisorFrame.style.height = "648px"
        supervisorFrame.style.width  = "842px"

        flexbox.appendChild(supervisorFrame)

        session.widgetController.ractive.observe(
          'ticksStarted'
        , (newValue, oldValue) ->
            if (newValue isnt oldValue)
              broadcastHNWPayload("hnw-widget-update", { event: { type: "ticksStarted", value: newValue } })
        )

        supervisorFrame.addEventListener('load', ->

          uuid = genUUID()
          role = Object.values(roles)[1]

          wind = supervisorFrame.contentWindow

          window.clients[uuid] =
            { roleName: role.name
            , window:   wind
            }

          # NOTE
          if role.onConnect?
            procedures[role.onConnect.toUpperCase()]()
            world.turtleManager.getTurtle(who).ask((-> SelfManager.self().setVariable("__hnw-username", "the supervisor")), false)
            session.updateWithoutRendering(uuid)

          # NOTE
          monitorUpdates = session.monitorsFor(uuid)

          supervisorFrame.contentWindow.postMessage({
            type:  "hnw-load-interface"
          , role:  role
          , token: uuid
          , view:  baseView
          }, "*")

          modelState = session.getModelState("")

          supervisorFrame.contentWindow.postMessage({
            type:        "nlw-state-update"
          , update:      Object.assign({}, modelState, { monitorUpdates })
          , sequenceNum: -1
          }, "*")

          session.subscribeWithID(wind, uuid)

        )

        studentFrame     = document.createElement("iframe")
        studentFrame.id  = "hnw-join-frame"
        studentFrame.src = "/hnw-join"

        studentFrame.style.border = "3px solid red"
        studentFrame.style.height = "471px"
        studentFrame.style.width  = "776px"

        flexbox.appendChild(studentFrame)

        studentFrame.addEventListener('load', ->

          genUUID = ->

            replacer =
              (c) ->
                r = Math.random() * 16 | 0
                v = if c == 'x' then r else (r & 0x3 | 0x8)
                v.toString(16)

            'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, replacer)

          uuid = genUUID()
          role = Object.values(roles)[0]
          # NOTE

          wind = studentFrame.contentWindow

          username = "Fake Client"
          who      = world.turtleManager.peekNextID()

          # TODO: This logic is wrong.  What if the `onConnect` makes multiple turtles?  Which `who` is owned by the client?
          # NOTE
          window.clients[uuid] =
            { roleName: role.name
            , username
            , who
            , window:   wind
            }

          # NOTE
          if role.onConnect?
            procedures[role.onConnect.toUpperCase()]()
            world.turtleManager.getTurtle(who).ask((-> SelfManager.self().setVariable("__hnw-username", username)), false)
            session.updateWithoutRendering(uuid)

          # NOTE
          monitorUpdates = session.monitorsFor(uuid)

          studentFrame.contentWindow.postMessage({
            type:  "hnw-load-interface"
          , role:  role
          , token: uuid
          , view:  baseView
          }, "*")

          modelState = session.getModelState("")

          studentFrame.contentWindow.postMessage({
            type:        "nlw-state-update"
          , update:      Object.assign({}, modelState, { monitorUpdates })
          , sequenceNum: -1
          }, "*")

          # NOTE
          session.subscribeWithID(wind, uuid)

        )

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
            type:   "nlw-resize"
          }, "*")

    window.setInterval(onInterval, 200)

  return

loadInitialModel()
setUpEventListeners()
handleFrameResize()
