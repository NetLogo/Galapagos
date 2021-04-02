loadingOverlay = document.getElementById("loading-overlay")
modelContainer = document.querySelector("#netlogo-model-container")
nlogoScript    = document.querySelector("#nlogo-code")

isStandaloneHTML = nlogoScript.textContent.length > 0

window.nlwAlerter = new NLWAlerter(document.getElementById("alert-overlay"), isStandaloneHTML)

cachedConfig = null # Role
session      = undefined

activeContainer = loadingOverlay

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
  #session.startLoop()
  return

window.addEventListener("message", (e) ->
  switch e.data.type
    when "config-with-json"

      cachedConfig = e.data.role

      hnwView  = cachedConfig.widgets.find((w) -> w.type is "hnwView")
      viewShim = { dimensions: { maxPxcor: 1, maxPycor: 1, minPxcor: -1, minPycor: -1, patchSize: 1, wrappingAllowedInX: true, wrappingAllowedInY: true }, fontSize: 12, type: "view" }
      view     = Object.assign({}, hnwView, viewShim)

      session?.teardown()
      window.nlwAlerter.hide()
      activeContainer = loadingOverlay
      Tortoise.loadHubNetWeb(modelContainer, cachedConfig, view, openSession)
      session.widgetController.ractive.set("isEditing", true)
      session.widgetController.ractive.set("isHNW"    , true)
      #session.subscribe(parent)

    when "request-save"
      e.source.postMessage({ parcel: cachedConfig, identifier: e.data.identifier }, e.origin)
    else
      console.warn("Unknown config event type: #{e.data.type}")
)
