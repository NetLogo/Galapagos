loadingOverlay  = document.getElementById("loading-overlay")
modelContainer  = document.querySelector("#netlogo-model-container")
nlogoScript     = document.querySelector("#nlogo-code")

activeContainer = loadingOverlay

session = undefined

isStandaloneHTML = nlogoScript.textContent.length > 0

window.nlwAlerter = new NLWAlerter(document.getElementById("alert-overlay"), isStandaloneHTML)

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

# () -> Unit
setUpEventListeners = ->

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
        update = session.getModelState("observer")
        e.source.postMessage({ update, type: "nlw-state-update", sequenceNum: -1 }, "*")
      when "nlw-request-view"
        base64 = session.widgetController.viewController.view.visibleCanvas.toDataURL("image/png")
        e.source.postMessage({ base64, type: "nlw-view" }, "*")
      when "nlw-subscribe-to-updates"
        session.subscribe(e.source)
      when "nlw-apply-update"

        { plotUpdates, ticks, viewUpdate } = e.data.update

        world.ticker.reset()
        world.ticker.importTicks(ticks)

        vc = session.widgetController.viewController
        vc.applyUpdate(viewUpdate)
        vc.repaint()

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
