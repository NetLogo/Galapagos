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

# () => Array[Object[Any]]
scrapeWidgets = ->

  pluck =
    (keys...) -> (widget) ->
      out = {}
      keys.forEach((key) -> out[key] = widget[key])
      out

  session.widgetController.widgets().map(
    (w) ->

      commons = { bottom: w.bottom, left: w.left, right: w.right, top: w.top, type: w.type }

      notCommons =
        (switch w.type
          when 'hnwTextBox'  then pluck("color", "display", "fontSize", "transparent")
          when 'hnwView'     then pluck("height", "width")
          when 'hnwSwitch'   then pluck("display", "on", "variable")
          when 'hnwButton'   then pluck("buttonKind", "disableUntilTicksStart", "forever", "hnwProcName", "source")
          when 'hnwSlider'   then pluck("default", "direction", "display", "max", "min", "step", "variable")
          when 'hnwChooser'  then pluck("choices", "currentChoice", "display", "variable")
          when 'hnwMonitor'  then pluck("display", "fontSize", "precision", "reporterStyle", "source")
          when 'hnwInputBox' then pluck("boxedValue", "variable")
          when 'hnwPlot'     then pluck("autoPlotOn", "display", "legendOn", "pens", "setupCode", "updateCode", "xAxis", "xmax", "xmin", "yAxis", "ymax", "ymin")
          when 'hnwOutput'   then pluck("fontSize")
          else
            console.warn("Impossible widget type: #{w.type}")
            {}
        )(w)

      Object.assign(commons, notCommons)

  )

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

      #Object.values(session.widgetController.configs.plotOps).forEach(
      #  (pops) -> pops.reset())

    when "request-save"
      e.source.postMessage(
        {
          parcel: { canJoinMidRun: cachedConfig.canJoinMidRun
                  , isSpectator:   cachedConfig.isSpectator
                  , limit:         cachedConfig.limit
                  , name:          cachedConfig.name
                  , onConnect:     cachedConfig.onConnect
                  , onCursorMove:  cachedConfig.onCursorMove
                  , onCursorClick: cachedConfig.onCursorClick
                  , onDisconnect:  cachedConfig.onDisconnect
                  , widgets:       scrapeWidgets()
                  }
        , identifier: e.data.identifier
        }
      , e.origin)
    else
      console.warn("Unknown config event type: #{e.data.type}")
)
