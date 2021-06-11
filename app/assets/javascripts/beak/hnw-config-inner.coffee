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
          when 'hnwButton'   then pluck("buttonKind", "disableUntilTicksStart", "display", "forever", "hnwProcName", "source")
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

window.notifyNewBreedVar = (varName) ->
  msg = { type: "new-breed-var", breed: cachedConfig.namePlural, var: varName }
  parent.postMessage(msg, "*")
  return

window.addEventListener("message", (e) ->
  switch e.data.type
    when "config-with-json"

      { globalVars, myVars, procedures } = e.data
      cachedConfig                       = e.data.role
      window.hnwRoleName                 = cachedConfig.name

      possibleMetaProcedures = (argsNum) ->
        procedures.filter(
          ({ argCount, isReporter, isUseableByTurtles }) ->
            argCount is argsNum and (not isReporter) and isUseableByTurtles
        )

      onConnectDD = document.getElementById('on-connect-dropdown')
      onConnectDD.innerHTML = ""

      onDisconnectDD = document.getElementById('on-disconnect-dropdown')
      onDisconnectDD.innerHTML = ""

      onClickDD = document.getElementById('on-click-dropdown')
      onClickDD.innerHTML = ""

      possibleMetaProcedures(0).forEach(

        ({ name }) ->

          option = document.createElement("option")
          option.innerHTML = name
          option.value     = name

          onDisconnectDD.appendChild(option.cloneNode(true))
          onDisconnectDD.value = cachedConfig.onDisconnect

      )

      procedures.filter(
        ({ argCount, isUseableByObserver }) ->
          argCount is 1 and isUseableByObserver
      ).forEach(

        ({ name }) ->

          option = document.createElement("option")
          option.innerHTML = name
          option.value     = name

          onConnectDD.appendChild(option)
          onConnectDD.value = cachedConfig.onConnect

      )

      possibleMetaProcedures(2).forEach(

        ({ name }) ->

          option = document.createElement("option")
          option.innerHTML = name
          option.value     = name

          onClickDD.appendChild(option.cloneNode(true))
          onClickDD.value = cachedConfig.onCursorClick

      )

      hnwView  = cachedConfig.widgets.find((w) -> w.type is "hnwView")
      viewShim = { dimensions: { maxPxcor: 1, maxPycor: 1, minPxcor: -1, minPycor: -1, patchSize: 1, wrappingAllowedInX: true, wrappingAllowedInY: true }, fontSize: 12, type: "view" }
      view     = Object.assign({}, hnwView, viewShim)

      session?.teardown()
      window.nlwAlerter.hide()
      activeContainer = loadingOverlay
      Tortoise.loadHubNetWeb(modelContainer, cachedConfig, view, openSession)
      session.widgetController.ractive.set("isEditing", true)
      session.widgetController.ractive.set("isHNW"    , true)
      session.widgetController.ractive.set("metadata" , { globalVars, myVars, procedures })
      #session.subscribe(parent)

      #Object.values(session.widgetController.configs.plotOps).forEach(
      #  (pops) -> pops.reset())

    when "request-save"
      onConnectBase = document.getElementById('on-connect-dropdown').value
      onClickBase   = document.getElementById('on-click-dropdown').value
      onDCBase      = document.getElementById('on-disconnect-dropdown').value
      e.source.postMessage(
        {
          parcel: { canJoinMidRun: cachedConfig.canJoinMidRun
                  , isSpectator:   cachedConfig.isSpectator
                  , limit:         cachedConfig.limit
                  , name:          cachedConfig.name
                  , namePlural:    cachedConfig.namePlural
                  , onConnect:     (if onConnectBase isnt "" then onConnectBase else null)
                  , onCursorMove:  cachedConfig.onCursorMove
                  , onCursorClick: (if onClickBase isnt "" then onClickBase else null)
                  , onDisconnect:  (if onDCBase isnt "" then onDCBase else null)
                  , widgets:       scrapeWidgets()
                  }
        , identifier: e.data.identifier
        , type:       "role-save-response"
        }
      , e.origin)

    when "update-metadata"
      session.widgetController.ractive.set("metadata", e.data.metadata)
    else
      console.warn("Unknown config event type: #{e.data.type}")
)
