phonyDims = { patchSize: 1
            , minPxcor: -10
            , maxPxcor: 10
            , minPycor: -10
            , maxPycor: 10
            , wrappingAllowedInX: true
            , wrappingAllowedInY: true
            }

phonyView  = { type: 'view'
             , left: 0
             , right: 21
             , top: 0
             , bottom: 21
             , fontSize: 8
             , updateMode: "Continuous"
             , showTickCounter: false
             , frameRate: 60
             , dimensions: phonyDims
             }

phonyModel = { code: ""
             , widgets: [phonyView]
             , commands: []
             , reporters: []
             , turtleShapes: []
             , linkShapes: []
             }

compiler   = new BrowserCompiler()
compiler.fromModel(phonyModel)

denil = (x) ->
  if x is "NIL" then null else x

convertMainButton = (left, top, right, bottom, bodyLines) ->
  [display, source, isForever, _, _, buttonKind, _, hotkey, _, _, duts] = bodyLines
  { type: "hnwButton"
  , left
  , right
  , top
  , bottom
  , display:                denil(display)
  , source
  , hnwProcName:            source
  , forever:                isForever is "T"
  , disableUntilTicksStart: duts is '1'
  , buttonKind:             "procedure"
  , actionKey:              denil(hotkey)?.slice(0, 1)
  }

globalEval = eval

convertMainChooser = (left, top, right, bottom, bodyLines) ->

  mungeChoices = (str) -> globalEval(compiler.compileReporter("[ #{str} ]").result)

  [disp, variable, choiceStr, defIndex] = bodyLines

  choices       = mungeChoices(choiceStr)
  currentChoice = parseInt(defIndex)
  display       = denil(disp)

  { type: "hnwChooser", left, right, top, bottom, display, variable, choices, currentChoice }

convertMainInput = (left, top, right, bottom, bodyLines) ->

  [variable, dfault, isMu, _, type] = bodyLines

  isMulti = isMu is '1'

  str1 = "String"
  str2 = "String (commands)"
  str3 = "String (reporter)"

  boxedValue =
    switch type
      when "Color", "Number" then { type, multiline: isMulti, value: parseFloat(dfault)      }
      when str1, str2, str3  then { type, multiline: isMulti, value: "#{denil(dfault) ? ""}" }
      else                        throw new Error("Unrecognized Input widget type: #{type}")

  { type: "hnwInputBox", left, right, top, bottom, variable, boxedValue }

convertMainMonitor = (left, top, right, bottom, bodyLines) ->
  [disp, _, decimals, _, fs] = bodyLines
  display   = denil(disp)
  fontSize  = parseInt(fs)
  precision = parseInt(decimals)
  { type: "hnwMonitor", left, right, top, bottom, display, source: "???1", reporterStyle: "???2", precision, fontSize }

convertMainOutput = (left, top, right, bottom, bodyLines) ->
  [fs] = bodyLines
  fontSize = parseInt(fs)
  { type: "hnwOutput", left, right, top, bottom, fontSize }

convertMainPlot = (left, top, right, bottom, bodyLines) ->

  parseBool = (x) -> x.toLowerCase() is "true"

  [display, xLabel, yLabel, xmn, xmx, ymn, ymx, apo, lo, setupAndUpdate, penHeader, penLines...] = bodyLines

  xAxis      = denil(xLabel)
  xmin       = parseFloat(xmn)
  xmax       = parseFloat(xmx)
  yAxis      = denil(yLabel)
  ymin       = parseFloat(ymn)
  ymax       = parseFloat(ymx)
  autoPlotOn = parseBool(apo)
  legendOn   = parseBool(lo)

  # Regex: Scoop up the contents of the string until an unescaped quote --Jason B. (6/28/21)
  regex = /^"(.*(?<!\\))" "(.*)"$/
  [_, setupCode, updateCode] = setupAndUpdate.match(regex)

  pens =
    if penHeader is "PENS"
      penLines.map(
        (line) ->
          pengex = /^"(.*(?<!\\))" ([^ ]*) ([^ ]*) ([^ ]*) ([a-zA-Z]*) "(.*(?<!\\))" "(.*)"$/
          [_, penDisplay, intervalStr, modeStr, colorStr, sil, penSetup, penUpdate] = line.match(pengex)
          interval = parseFloat(intervalStr)
          mode     = parseInt(  modeStr)
          color    = parseFloat(colorStr)
          inLegend = parseBool(sil)
          { type: "pen", display: penDisplay, interval, mode, color, inLegend
          , setupCode: penSetup, updateCode: penUpdate }
      )
    else
      []

  { type: "hnwPlot", left, right, top, bottom
  , display, xAxis, yAxis, xmin, xmax, ymin, ymax
  , autoPlotOn, legendOn, setupCode, updateCode, pens }

convertMainSlider = (left, top, right, bottom, bodyLines) ->

  [disp, variable, min, max, dfault, stepStr, _, unis, dir] = bodyLines

  display   = denil(disp)
  default_  = parseFloat(dfault)
  step      = parseFloat(stepStr)
  units     = denil(unis)
  direction = dir.toLowerCase()

  { type: "hnwSlider", left, right, top, bottom, display, variable
  , min, max, 'default': default_, step, units, direction
  }

convertMainSwitch = (left, top, right, bottom, bodyLines) ->
  [disp, variable, isOff] = bodyLines
  display = denil(disp)
  isOn    = parseInt(isOff) is 0
  { type: "hnwSwitch", left, right, top, bottom, display, variable, 'on': isOn }

convertMainLabel = (left, top, right, bottom, bodyLines) ->
  [disp, fontSizeStr, colorStr, isTranspStr] = bodyLines
  color       = parseFloat(colorStr)
  display     = disp.replace(/\\n/, "\n")
  fontSize    = parseInt(fontSizeStr)
  transparent = isTranspStr is '1'
  { type: "hnwTextBox", left, right, top, bottom, display, color, fontSize, transparent }

convertMainView = (left, top, right, bottom, bodyLines) ->
  height = right - left
  width  = bottom - top
  { type: "hnwView", left, right, top, bottom, height, width }

# (String) => Object[Any]
convertMainWidget = (widgetNlogo) ->
  [header, leftStr, topStr, rightStr, bottomStr, bodyLines...] = widgetNlogo.split('\n')
  [left, top, right, bottom] = [leftStr, topStr, rightStr, bottomStr].map((x) -> parseInt(x))
  switch header
    when "BUTTON"          then convertMainButton( left, top, right, bottom, bodyLines)
    when "CHOOSER"         then convertMainChooser(left, top, right, bottom, bodyLines)
    when "INPUTBOX"        then convertMainInput(  left, top, right, bottom, bodyLines)
    when "MONITOR"         then convertMainMonitor(left, top, right, bottom, bodyLines)
    when "OUTPUT"          then convertMainOutput( left, top, right, bottom, bodyLines)
    when "PLOT"            then convertMainPlot(   left, top, right, bottom, bodyLines)
    when "SLIDER"          then convertMainSlider( left, top, right, bottom, bodyLines)
    when "SWITCH"          then convertMainSwitch( left, top, right, bottom, bodyLines)
    when "TEXTBOX"         then convertMainLabel(  left, top, right, bottom, bodyLines)
    when "GRAPHICS-WINDOW" then convertMainView(   left, top, right, bottom, bodyLines)
    else throw Error("Invalid main widget header: #{header}")

convertClientButton = (left, top, right, bottom, bodyLines) ->
  [display, _, _, _, _, _, _, hotkey] = bodyLines
  { type: "hnwButton"
  , left
  , right
  , top
  , bottom
  , display:                denil(display)
  , source:                 ""
  , hnwProcName:            ""
  , forever:                false
  , disableUntilTicksStart: false
  , buttonKind:             "turtle-procedure"
  , actionKey:              denil(hotkey)?.slice(0, 1)
  }

convertClientChooser = convertMainChooser

convertClientInput = convertMainInput

convertClientMonitor = (left, top, right, bottom, bodyLines) ->

  [disp, _, precisionStr] = bodyLines

  display   = denil(disp)
  precision = parseInt(precisionStr)

  { type: "hnwMonitor", left, right, top, bottom, display
  , source: "???1", reporterStyle: "turtle-procedure"
  , precision, fontSize: 10
  }

convertClientOutput = convertMainOutput

convertClientPlot = convertMainPlot

convertClientSlider = convertMainSlider

convertClientSwitch = convertMainSwitch

convertClientLabel = convertMainLabel

convertClientView = convertMainView

# (String) => Object[Any]
convertClientWidget = (widgetNlogo) ->
  [header, leftStr, topStr, rightStr, bottomStr, bodyLines...] = widgetNlogo.split('\n')
  [left, top, right, bottom] = [leftStr, topStr, rightStr, bottomStr].map((x) -> parseInt(x))
  switch header
    when "BUTTON"   then convertClientButton( left, top, right, bottom, bodyLines)
    when "CHOOSER"  then convertClientChooser(left, top, right, bottom, bodyLines)
    when "INPUTBOX" then convertClientInput(  left, top, right, bottom, bodyLines)
    when "MONITOR"  then convertClientMonitor(left, top, right, bottom, bodyLines)
    when "OUTPUT"   then convertClientOutput( left, top, right, bottom, bodyLines)
    when "PLOT"     then convertClientPlot(   left, top, right, bottom, bodyLines)
    when "SLIDER"   then convertClientSlider( left, top, right, bottom, bodyLines)
    when "SWITCH"   then convertClientSwitch( left, top, right, bottom, bodyLines)
    when "TEXTBOX"  then convertClientLabel(  left, top, right, bottom, bodyLines)
    when "VIEW"     then convertClientView(   left, top, right, bottom, bodyLines)
    else throw Error("Invalid client widget header: #{header}")

# (String) => Object[Any]
genMainRole = (widgetNlogo) ->
  { afterDisconnect:    null
  , canJoinMidRun:      true
  , onCursorMove:       null
  , onCursorClick:      null
  , onDisconnect:       null
  , widgets:            widgetNlogo.split('\n\n').map(convertMainWidget)
  , name:               "teacher"
  , namePlural:         "teachers"
  , onConnect:          null
  , perspectiveVar:     null
  , viewOverrideVar:    null
  , highlightMainColor: "#008000"
  , limit:              1
  , isSpectator:        true
  }

# (String) => Object[Any]
genClientRole = (widgetNlogo) ->
  widgets =
    if widgetNlogo isnt ''
      widgetNlogo.split('\n\n').map(convertClientWidget)
    else
      [{ type: "hnwView", left: 200, right: 650, top: 0, bottom: 450, height: 450, width: 450 }]

  { afterDisconnect:    null
  , canJoinMidRun:      true
  , onCursorMove:       null
  , onCursorClick:      null
  , onDisconnect:       null
  , widgets
  , name:               "student"
  , namePlural:         "students"
  , onConnect:          null
  , perspectiveVar:     null
  , viewOverrideVar:    null
  , highlightMainColor: "#008000"
  , limit:              -1
  , isSpectator:        false
  }

# (String) => Object[Any]
generateHNWConfig = (nlogo) ->

  [_, widgets, _, _, _, _, _, clientWidgets, _, _, _] = nlogo.split('@#$#@#$#@')

  mainRole   = genMainRole(widgets.trim())
  clientRole = genClientRole(clientWidgets.trim())

  outConfig =
    { roles:           [mainRole, clientRole]
    , onIterate:       ""
    , onStart:         ""
    , targetFrameRate: 20
    , version:         "hnw-alpha-1"
    , type:            "hubnet-web"
    }

  outConfig

export default generateHNWConfig
