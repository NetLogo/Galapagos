import { netlogoColorToRGB, rgbaArrayToARGBInt } from "/colors.js"

denil = (x) ->
  if x is "NIL" then null else x

phonyDims = { patchSize: 1
            , minPxcor: -10
            , maxPxcor: 10
            , minPycor: -10
            , maxPycor: 10
            , wrappingAllowedInX: true
            , wrappingAllowedInY: true
            }

phonyView  = { type: 'view'
             , x: 0
             , width: 21
             , y: 0
             , height: 21
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

convertMainButton = (x, y, width, height, bodyLines) ->
  [display, source, isForever, _, _, buttonKind, _, hotkey, _, _, duts] = bodyLines
  { type: "hnwButton"
  , x
  , y
  , width
  , height
  , display:                denil(display)
  , source
  , hnwProcName:            source
  , forever:                isForever is "T"
  , disableUntilTicksStart: duts is '1'
  , buttonKind:             "procedure"
  , actionKey:              denil(hotkey)?.slice(0, 1)
  }

globalEval = eval

convertMainChooser = (x, y, width, height, bodyLines) ->

  mungeChoices = (str) -> globalEval(compiler.compileReporter("[ #{str} ]").result)

  [disp, variable, choiceStr, defIndex] = bodyLines

  choices       = mungeChoices(choiceStr)
  currentChoice = parseInt(defIndex)
  display       = denil(disp)

  { type: "hnwChooser", x, y, width, height, display, variable, choices, currentChoice }

convertMainInput = (x, y, width, height, bodyLines) ->

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

  { type: "hnwInputBox", x, y, width, height, variable, boxedValue }

convertMainMonitor = (x, y, width, height, bodyLines) ->
  [disp, _, decimals, _, fs] = bodyLines
  display   = denil(disp)
  fontSize  = parseInt(fs)
  precision = parseInt(decimals)
  { type: "hnwMonitor", x, y, width, height, display, source: "???1", reporterStyle: "???2", precision, fontSize }

convertMainOutput = (x, y, width, height, bodyLines) ->
  [fs] = bodyLines
  fontSize = parseInt(fs)
  { type: "hnwOutput", x, y, width, height, fontSize }

convertMainPlot = (x, y, width, height, bodyLines) ->

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

  { type: "hnwPlot", x, y, width, height
  , display, xAxis, yAxis, xmin, xmax, ymin, ymax
  , autoPlotX: autoPlotOn, autoPlotY: autoPlotOn
  , legendOn, setupCode, updateCode, pens }

convertMainSlider = (x, y, width, height, bodyLines) ->

  [disp, variable, min, max, dfault, stepStr, _, unis, dir] = bodyLines

  display   = denil(disp)
  default_  = parseFloat(dfault)
  step      = parseFloat(stepStr)
  units     = denil(unis)
  direction = dir.toLowerCase()

  { type: "hnwSlider", x, y, width, height, display, variable
  , min, max, 'default': default_, step, units, direction
  }

convertMainSwitch = (x, y, width, height, bodyLines) ->
  [disp, variable, isOff] = bodyLines
  display = denil(disp)
  isOn    = parseInt(isOff) is 0
  { type: "hnwSwitch", x, y, width, height, display, variable, 'on': isOn }

convertMainLabel = (x, y, width, height, bodyLines) ->
  [disp, fontSizeStr, colorStr, isTranspStr] = bodyLines
  colorRGBA       = netlogoColorToRGB(parseFloat(colorStr))
  colorRGBA.push(255)
  textColorLight  = rgbaArrayToARGBInt(colorRGBA)
  display         = disp.replace(/\\n/, "\n")
  fontSize        = parseInt(fontSizeStr)
  bgRGBA          = if isTranspStr is '1' then [255, 255, 255, 0] else [255, 255, 255, 255]
  backgroundLight = rgbaArrayToARGBInt(bgRGBA)

  { type: "hnwTextBox", x, y, width, height, textColorLight, backgroundLight, display, fontSize, markdown: false }

convertMainView = (x, y, width, height, bodyLines) ->
  { type: "hnwView", x, y, width, height }

# (String) => Object[Any]
convertMainWidget = (widgetNlogo) ->
  [header, leftStr, topStr, rightStr, bottomStr, bodyLines...] = widgetNlogo.split('\n')
  [left, top, right, bottom] = [leftStr, topStr, rightStr, bottomStr].map((x) -> parseInt(x))
  x      = left
  y      = top
  width  = right  - left
  height = bottom - top
  switch header
    when "BUTTON"          then convertMainButton( x, y, width, height, bodyLines)
    when "CHOOSER"         then convertMainChooser(x, y, width, height, bodyLines)
    when "INPUTBOX"        then convertMainInput(  x, y, width, height, bodyLines)
    when "MONITOR"         then convertMainMonitor(x, y, width, height, bodyLines)
    when "OUTPUT"          then convertMainOutput( x, y, width, height, bodyLines)
    when "PLOT"            then convertMainPlot(   x, y, width, height, bodyLines)
    when "SLIDER"          then convertMainSlider( x, y, width, height, bodyLines)
    when "SWITCH"          then convertMainSwitch( x, y, width, height, bodyLines)
    when "TEXTBOX"         then convertMainLabel(  x, y, width, height, bodyLines)
    when "GRAPHICS-WINDOW" then convertMainView(   x, y, width, height, bodyLines)
    else throw Error("Invalid main widget header: #{header}")

convertClientButton = (x, y, width, height, bodyLines) ->
  [display, _, _, _, _, _, _, hotkey] = bodyLines
  { type: "hnwButton"
  , x
  , y
  , width
  , height
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

convertClientMonitor = (x, y, width, height, bodyLines) ->

  [disp, _, precisionStr] = bodyLines

  display   = denil(disp)
  precision = parseInt(precisionStr)

  { type: "hnwMonitor", x, y, width, height, display
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
  x      = left
  y      = top
  width  = right  - left
  height = bottom - top
  switch header
    when "BUTTON"   then convertClientButton( x, y, width, height, bodyLines)
    when "CHOOSER"  then convertClientChooser(x, y, width, height, bodyLines)
    when "INPUTBOX" then convertClientInput(  x, y, width, height, bodyLines)
    when "MONITOR"  then convertClientMonitor(x, y, width, height, bodyLines)
    when "OUTPUT"   then convertClientOutput( x, y, width, height, bodyLines)
    when "PLOT"     then convertClientPlot(   x, y, width, height, bodyLines)
    when "SLIDER"   then convertClientSlider( x, y, width, height, bodyLines)
    when "SWITCH"   then convertClientSwitch( x, y, width, height, bodyLines)
    when "TEXTBOX"  then convertClientLabel(  x, y, width, height, bodyLines)
    when "VIEW"     then convertClientView(   x, y, width, height, bodyLines)
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
      [{ type: "hnwView", x: 200, y: 0, height: 450, width: 450 }]

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

# (String) => [Object[Any], Object[Any]]
genOldFormatRoles = (nlogo) ->
  [_, widgets, _, _, _, _, _, clientWidgets, _, _, _] = nlogo.split('@#$#@#$#@')
  mainRole   = genMainRole(widgets.trim())
  clientRole = genClientRole(clientWidgets.trim())
  [mainRole, clientRole]

export default genOldFormatRoles
