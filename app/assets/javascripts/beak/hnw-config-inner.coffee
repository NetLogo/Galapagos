import AlertDisplay from "/alert-display.js"
import Tortoise     from "./tortoise.js"

cachedConfig = null      # Role
session      = undefined # Session

loadingOverlay  = document.getElementById("loading-overlay")
activeContainer = loadingOverlay
modelContainer  = document.querySelector("#netlogo-model-container")
nlogoScript     = document.querySelector("#nlogo-code")

isStandaloneHTML = nlogoScript.textContent.length > 0

listeners = [] # Array[Listener]

aCon    = document.getElementById("alert-container")
alerter = new AlertDisplay(aCon, isStandaloneHTML)
listeners.push(alerter)

nullChoiceText = '<no selection>'

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
  loadingOverlay.style.display = "none"
  alerter.setWidgetController(session.widgetController)
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
          when 'hnwTextBox'  then pluck( "color", "display", "fontSize"
                                       , "transparent")
          when 'hnwView'     then pluck( "height", "width")
          when 'hnwSwitch'   then pluck( "display", "on", "variable")
          when 'hnwButton'   then pluck( "actionKey", "buttonKind"
                                       , "disableUntilTicksStart", "display"
                                       , "forever", "hnwProcName", "source")
          when 'hnwSlider'   then pluck( "default", "direction", "display", "max"
                                       , "min", "step", "variable")
          when 'hnwChooser'  then pluck( "choices", "currentChoice", "display"
                                       , "variable")
          when 'hnwMonitor'  then pluck( "display", "fontSize", "precision"
                                       , "reporterStyle", "source")
          when 'hnwInputBox' then pluck( "boxedValue", "variable")
          when 'hnwPlot'     then pluck( "autoPlotOn", "display", "legendOn", "pens"
                                       , "setupCode", "updateCode", "xAxis", "xmax"
                                       , "xmin", "yAxis", "ymax", "ymin")
          when 'hnwOutput'   then pluck("fontSize")
          else
            console.warn("Impossible widget type: #{w.type}")
            {}
        )(w)

      Object.assign(commons, notCommons)

  )

# () => Unit
document.getElementById("delete-role-button").onclick = ->
  if confirm("Are you sure you want to delete this role?")
    parent.postMessage({ type: "delete-me" }, "*")
  return

# (Event) => String
document.getElementById("max-count-picker").oninput = (event) ->
  s = event.target.value
  if s is "."
    "."
  else if s is "-"
    "-"
  else
    x = parseFloat(s)
    event.target.value =
      if x < 0
        -1
      else if x > 999
        999
      else if x isnt Math.floor(x)
        Math.floor(x)
      else
        x

# (String, Array[String], String) => Unit
populateOptions = (elemID, choices, dfault) ->

  elem           = document.getElementById(elemID)
  elem.innerHTML = ""

  choices.concat([nullChoiceText]).forEach(
    (str) ->
      option           = document.createElement("option")
      option.innerText = str
      option.value     = str
      elem.appendChild(option)
      return
  )

  elem.value = dfault

  # Fixing value when item isn't in choice list --Jason B. (6/28/21)
  elem.value =
    if elem.value isnt ''
      elem.value
    else
      nullChoiceText

  return

window.onmessage = (e) ->
  switch e.data.type
    when "config-with-json"

      { globalVars, myVars, procedures } = e.data
      cachedConfig                       = e.data.role

      possibleMetaProcedures = (argsNum) ->
        procedures.filter(
          ({ argCount, isReporter, isUseableByTurtles }) ->
            argCount is argsNum and (not isReporter) and isUseableByTurtles
        )

      afterDisconnectChoices =
        procedures.filter(
          ({ argCount, isUseableByObserver }) ->
            argCount is 1 and isUseableByObserver
        )

      onConnectChoices =
        procedures.filter(
          ({ argCount, isUseableByObserver }) ->
            argCount <= 1 and isUseableByObserver
        )

      toNames = (arr) -> arr.map((x) -> x.name)

      populateOptions('after-disconnect-dropdown', toNames(afterDisconnectChoices   ), cachedConfig.afterDisconnect)
      populateOptions('on-connect-dropdown'      , toNames(onConnectChoices         ), cachedConfig.onConnect      )
      populateOptions('on-disconnect-dropdown'   , toNames(possibleMetaProcedures(0)), cachedConfig.onDisconnect   )
      populateOptions('on-click-dropdown'        , toNames(possibleMetaProcedures(2)), cachedConfig.onCursorClick  )
      populateOptions('on-cursor-up-dropdown'    , toNames(possibleMetaProcedures(2)), cachedConfig.onCursorRelease)
      populateOptions('on-move-dropdown'         , toNames(possibleMetaProcedures(2)), cachedConfig.onCursorMove   )
      populateOptions('perspective-dropdown'     , myVars                            , cachedConfig.perspectiveVar )
      populateOptions('view-override-dropdown'   , myVars                            , cachedConfig.viewOverrideVar)

      document.getElementById('can-join-midrun-checkbox'  ).checked = cachedConfig.canJoinMidRun
      document.getElementById('is-spectator-role-checkbox').checked = cachedConfig.isSpectator
      document.getElementById('role-singular-input'       ).value   = cachedConfig.name
      document.getElementById('role-plural-input'         ).value   = cachedConfig.namePlural
      document.getElementById('max-count-picker'          ).value   = cachedConfig.limit
      document.getElementById('highlight-main-color'      ).value   = cachedConfig.highlightMainColor

      hnwView = cachedConfig.widgets.find((w) -> w.type is "hnwView")

      viewShim = { dimensions: { maxPxcor: 1
                               , maxPycor: 1
                               , minPxcor: -1
                               , minPycor: -1
                               , patchSize: 1
                               , wrappingAllowedInX: true
                               , wrappingAllowedInY: true
                               }
                 , fontSize: 12
                 , type: "view"
                 }

      view = Object.assign({}, hnwView, viewShim)

      session?.teardown()
      activeContainer = loadingOverlay
      Tortoise.loadHubNetWeb(modelContainer, cachedConfig, view, openSession, listeners)
      ractive = session.widgetController.ractive

      ractive.set("isEditing", true )
      ractive.set("isHNW"    , true )
      ractive.set("isHNWHost", false)
      ractive.set("metadata" , { globalVars, myVars, procedures })
      #session.subscribe(parent, "Authoring frame")

      ractive.fire("unbind-keys")

      ractive.on("*.new-breed-var", (_, varName) ->
        msg = { type: "new-breed-var", breed: cachedConfig.namePlural, var: varName }
        parent.postMessage(msg, "*")
        return
      )

      #Object.values(session.widgetController.configs.plotOps).forEach(
      #  (pops) -> pops.reset())

    when "request-save"

      orNull =
        (x) ->
          if x isnt nullChoiceText
            x
          else
            null

      afterDisconnect =   orNull(document.getElementById('after-disconnect-dropdown' ).value)
      canJoinMidRun   =          document.getElementById('can-join-midrun-checkbox'  ).checked
      isSpectator     =          document.getElementById('is-spectator-role-checkbox').checked
      limit           = parseInt(document.getElementById('max-count-picker'          ).value)
      name            =   orNull(document.getElementById('role-singular-input'       ).value)
      namePlural      =   orNull(document.getElementById('role-plural-input'         ).value)
      onConnect       =   orNull(document.getElementById('on-connect-dropdown'       ).value)
      onCursorClick   =   orNull(document.getElementById('on-click-dropdown'         ).value)
      onCursorMove    =   orNull(document.getElementById('on-move-dropdown'          ).value)
      onCursorRelease =   orNull(document.getElementById('on-cursor-up-dropdown'     ).value)
      onDisconnect    =   orNull(document.getElementById('on-disconnect-dropdown'    ).value)
      perspectiveVar  =   orNull(document.getElementById('perspective-dropdown'      ).value)
      viewOverrideVar =   orNull(document.getElementById('view-override-dropdown'    ).value)
      hlColor         =   orNull(document.getElementById('highlight-main-color'      ).value)

      e.source.postMessage(
        {
          parcel: { afterDisconnect
                  , canJoinMidRun
                  , isSpectator
                  , limit
                  , highlightMainColor: hlColor
                  , name
                  , namePlural
                  , onConnect
                  , onCursorClick
                  , onCursorMove
                  , onCursorRelease
                  , onDisconnect
                  , perspectiveVar
                  , viewOverrideVar
                  , widgets:        scrapeWidgets()
                  }
        , identifier: e.data.identifier
        , type:       "role-save-response"
        }
      , e.origin)

    when "update-metadata"
      session.widgetController.ractive.set("metadata", e.data.metadata)
    else
      console.warn("Unknown config event type: #{e.data.type}")
