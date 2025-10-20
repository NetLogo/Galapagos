import { nlogoXMLToDoc } from "./tortoise-utils.js"

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

parseBool = (x) -> x.toLowerCase() is "true"

convertMainButton = (x, y, width, height, widgetElement) ->
  display           = widgetElement.getAttribute("display")
  source            = widgetElement.innerHTML
  forever           = parseBool(widgetElement.getAttribute("forever"))
  disableUntilTicks = parseBool(widgetElement.getAttribute("disableUntilTicks"))
  actionKey         = widgetElement.getAttribute("actionKey")

  { type: "hnwButton"
  , x
  , y
  , width
  , height
  , display
  , source
  , hnwProcName:            source
  , forever
  , disableUntilTicksStart: disableUntilTicks
  , buttonKind:             "procedure"
  , actionKey
  }

globalEval = eval

convertMainChooser = (x, y, width, height, widgetElement) ->

  mungeChoices = (str) -> globalEval(compiler.compileReporter(str).result)

  variable      = widgetElement.getAttribute("variable")
  currentChoice = parseInt(widgetElement.getAttribute("current"))
  display       = widgetElement.getAttribute("display")

  choices = Array.from(widgetElement.children).map( (choice) ->
    choiceType = choice.getAttribute("type")
    switch choiceType
      when "double" then parseFloat(choice.getAttribute("value"))
      when "string" then choice.getAttribute("value")
      when "list"   then mungeChoices(choice.innerHTML)
      else               throw new Error("Unrecognized Chooser widget choice type: #{choiceType}")
  )

  { type: "hnwChooser", x, y, width, height, display, variable, choices, currentChoice }

convertMainInput = (x, y, width, height, widgetElement) ->
  variable   = widgetElement.getAttribute("variable")
  multiline  = parseBool(widgetElement.getAttribute("multiline"))
  defaultStr = widgetElement.getAttribute("default")
  type       = widgetElement.getAttribute("type")

  str1 = "string"
  str2 = "command"
  str3 = "reporter"

  boxedValue =
    switch type
      when "color", "number" then { type, multiline, value: parseFloat(defaultStr) }
      when str1, str2, str3  then { type, multiline, value: defaultStr ? ""        }
      else                        throw new Error("Unrecognized Input widget type: #{type}")

  { type: "hnwInputBox", x, y, width, height, variable, boxedValue }

convertMainMonitor = (x, y, width, height, widgetElement) ->
  display   = widgetElement.getAttribute("display")
  fontSize  = parseInt(widgetElement.getAttribute("fontSize"))
  precision = parseInt(widgetElement.getAttribute("precision"))
  { type: "hnwMonitor", x, y, width, height, display, source: "???1", reporterStyle: "???2", precision, fontSize }

convertMainOutput = (x, y, width, height, widgetElement) ->
  fontSize = parseInt(widgetElement.getAttribute("fontSize"))
  { type: "hnwOutput", x, y, width, height, fontSize }

convertMainPlot = (x, y, width, height, widgetElement) ->
  display   = widgetElement.getAttribute("display")
  xAxis     = widgetElement.getAttribute("xAxis")
  xmin      = parseFloat(widgetElement.getAttribute("xMin"))
  xmax      = parseFloat(widgetElement.getAttribute("xMax"))
  yAxis     = widgetElement.getAttribute("yAxis")
  ymin      = parseFloat(widgetElement.getAttribute("yMin"))
  ymax      = parseFloat(widgetElement.getAttribute("yMax"))
  autoPlotX = parseBool(widgetElement.getAttribute("autoPlotX"))
  autoPlotY = parseBool(widgetElement.getAttribute("autoPlotY"))
  legendOn  = parseBool(widgetElement.getAttribute("legend"))

  setupCode  = widgetElement.getElementsByTagName( "setup").item(0).innerHTML ? ""
  updateCode = widgetElement.getElementsByTagName("update").item(0).innerHTML ? ""

  penElements = Array.from(widgetElement.getElementsByTagName("pens"))

  pens =
    penElements.map( (penElement) ->
      penDisplay = penElement.getAttribute("display")
      interval   = parseFloat(penElement.getAttribute("interval"))
      mode       = parseInt(penElement.getAttribute("mode"))
      color      = parseFloat(penElement.getAttribute("color"))
      inLegend   = parseBool(penElement.getAttribute("legend"))

      penSetupCode  = widgetElement.getElementsByTagName( "setup").item(0).innerHTML ? ""
      penUpdateCode = widgetElement.getElementsByTagName("update").item(0).innerHTML ? ""

      {
        type: "pen", display: penDisplay, interval, mode, color, inLegend
      , setupCode: penSetupCode, updateCode: penUpdateCode
      }
    )

  { type: "hnwPlot", x, y, width, height
  , display, xAxis, yAxis, xmin, xmax, ymin, ymax
  , autoPlotX, autoPlotY, legendOn, setupCode, updateCode, pens }

convertMainSlider = (x, y, width, height, widgetElement) ->
  display   = widgetElement.getAttribute("display")
  variable  = widgetElement.getAttribute("variable")
  min       = widgetElement.getAttribute("min")
  max       = widgetElement.getAttribute("max")
  default_  = parseFloat(widgetElement.getAttribute("default"))
  step      = parseFloat(widgetElement.getAttribute("step"))
  units     = widgetElement.getAttribute("units")
  direction = widgetElement.getAttribute("direction").toLowerCase()

  { type: "hnwSlider", x, y, width, height, display, variable
  , min, max, 'default': default_, step, units, direction
  }

convertMainSwitch = (x, y, width, height, widgetElement) ->
  variable = widgetElement.getAttribute("variable")
  isOn     = parseBool(widgetElement.getAttribute("on"))
  display  = widgetElement.getAttribute("display")
  { type: "hnwSwitch", x, y, width, height, display, variable, on: isOn }

convertMainLabel = (x, y, width, height, widgetElement) ->
  textColorLight  = parseFloat(widgetElement.getAttribute("textColorLight"))
  backgroundLight = parseFloat(widgetElement.getAttribute("backgroundLight"))
  display         = widgetElement.innerHTML
  fontSize        = parseInt(widgetElement.getAttribute("fontSize"))
  markdown        = parseBool(widgetElement.getAttribute("markdown"))
  { type: "hnwTextBox", x, y, width, height, textColorLight, backgroundLight, display, fontSize, markdown }

convertMainView = (x, y, width, height, widgetElement) ->
  { type: "hnwView", x, y, width, height }

# (Element) => Object[Any]
convertMainWidget = (widgetElement) ->
  header                = widgetElement.nodeName.toUpperCase()
  [x, y, width, height] = ["x", "y", "width", "height"].map( (attr) -> parseInt(widgetElement.getAttribute(attr)) )
  switch header
    when "BUTTON"  then convertMainButton( x, y, width, height, widgetElement)
    when "CHOOSER" then convertMainChooser(x, y, width, height, widgetElement)
    when "INPUT"   then convertMainInput(  x, y, width, height, widgetElement)
    when "MONITOR" then convertMainMonitor(x, y, width, height, widgetElement)
    when "OUTPUT"  then convertMainOutput( x, y, width, height, widgetElement)
    when "PLOT"    then convertMainPlot(   x, y, width, height, widgetElement)
    when "SLIDER"  then convertMainSlider( x, y, width, height, widgetElement)
    when "SWITCH"  then convertMainSwitch( x, y, width, height, widgetElement)
    when "NOTE"    then convertMainLabel(  x, y, width, height, widgetElement)
    when "VIEW"    then convertMainView(   x, y, width, height, widgetElement)
    else throw Error("Invalid main widget node name: #{header}")

convertClientButton = (x, y, width, height, widgetElement) ->
  display   = getAttribute("display")
  actionKey = widgetElement.getAttribute("actionKey")

  { type: "hnwButton"
  , x
  , y
  , width
  , height
  , display
  , source:                 ""
  , hnwProcName:            ""
  , forever:                false
  , disableUntilTicksStart: false
  , buttonKind:             "turtle-procedure"
  , actionKey
  }

convertClientChooser = convertMainChooser

convertClientInput = convertMainInput

convertClientMonitor = (x, y, width, height, widgetElement) ->
  display   = widgetElement.getAttribute("display")
  precision = parseInt(widgetElement.getAttribute("precision"))

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
convertClientWidget = (widgetElement) ->
  header                = widgetElement.nodeName.toUpperCase()
  [x, y, width, height] = ["x", "y", "width", "height"].map( (attr) -> parseInt(widgetElement.getAttribute(attr)) )
  switch header
    when "BUTTON"   then convertClientButton( x, y, width, height, widgetElement)
    when "CHOOSER"  then convertClientChooser(x, y, width, height, widgetElement)
    when "INPUT"    then convertClientInput(  x, y, width, height, widgetElement)
    when "MONITOR"  then convertClientMonitor(x, y, width, height, widgetElement)
    when "OUTPUT"   then convertClientOutput( x, y, width, height, widgetElement)
    when "PLOT"     then convertClientPlot(   x, y, width, height, widgetElement)
    when "SLIDER"   then convertClientSlider( x, y, width, height, widgetElement)
    when "SWITCH"   then convertClientSwitch( x, y, width, height, widgetElement)
    when "NOTE"     then convertClientLabel(  x, y, width, height, widgetElement)
    when "VIEW"     then convertClientView(   x, y, width, height, widgetElement)
    else throw Error("Invalid client widget node name: #{header}")

# (Element) => Object[Any]
genMainRole = (widgetsElement) ->
  widgets = Array.from(widgetsElement.children).map(convertMainWidget)

  { afterDisconnect:    null
  , canJoinMidRun:      true
  , onCursorMove:       null
  , onCursorClick:      null
  , onDisconnect:       null
  , widgets:            widgets
  , name:               "teacher"
  , namePlural:         "teachers"
  , onConnect:          null
  , perspectiveVar:     null
  , viewOverrideVar:    null
  , highlightMainColor: "#008000"
  , limit:              1
  , isSpectator:        true
  }

notImplemented = () ->
  return new Exception("Functionality not yet implemented.")

# (Element) => Object[Any]
genClientRole = (clientWidgetsElement) ->
  widgets =
    if clientWidgetsElement?
      Array.from(clientWidgetsElement.children).map(convertClientWidget)
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
genXMLRoles = (nlogox) ->
  nlogoDoc             = nlogoXMLToDoc(nlogox)
  widgetsElement       = nlogoDoc.querySelector("widgets")
  clientWidgetsElement = nlogoDoc.querySelector("hubNetClient")
  mainRole             = genMainRole(widgetsElement)
  clientRole           = genClientRole(clientWidgetsElement)
  [mainRole, clientRole]

# (String) => Object[Any]
generateHNWConfig = (nlogox) ->

  [mainRole, clientRole] = genXMLRoles(nlogox)

  outConfig =
    { roles:           [mainRole, clientRole]
    , onIterate:       ""
    , onStart:         ""
    , targetFrameRate: 20
    , version:         "hnw-beta-1"
    , type:            "hubnet-web"
    }

  outConfig

export default generateHNWConfig
