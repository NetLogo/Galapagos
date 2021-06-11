###
#

    hChooserP :: Parser Widget
    hChooserP =
      do
        void $ string "CHOOSER"
        void newline
        left      <- nlInt
        void newline
        top       <- nlInt
        void newline
        right     <- nlInt
        void newline
        bottom    <- nlInt
        void newline
        display   <- nilText
        void newline
        varName   <- text
        void newline
        choiceStr <- text
        void newline
        defIndex  <- nlInt

        let choices = mungeChoices choiceStr

        return $ HostChooser left right top bottom display varName choices defIndex

    hInputP :: Parser Widget
    hInputP =
      do
        void $ string "INPUTBOX"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        varName  <- text
        void newline
        default' <- text
        void newline
        isMu     <- binDigitChar
        void newline
        void $ text
        void newline
        type' <- text

        let isMulti    = isMu == '1'
        let inputValue = genInputValue default' isMulti type'

        return $ HostInputBox left right top bottom varName inputValue

    hMonitorP :: Parser Widget
    hMonitorP =
      do
        void $ string "MONITOR"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- text
        void newline
        void $ text
        void newline
        decimals <- nlInt
        void newline
        void $ text
        void newline
        fontSize <- nlInt

        return $ HostMonitor left right top bottom display decimals fontSize

    hPlotP :: Parser Widget
    hPlotP =
      do
        void $ string "PLOT"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- text
        void newline
        xLabel   <- text
        void newline
        yLabel   <- text
        void newline
        xMin     <- nlNum
        void newline
        xMax     <- nlNum
        void newline
        yMin     <- nlNum
        void newline
        yMax     <- nlNum
        void newline
        isAuto   <- bool
        void newline
        isLegend <- bool
        void newline
        setup    <- stringLiteral
        void $ string " "
        update   <- stringLiteral
        void newline
        void $ string "PENS"
        penBlockM <- optional . try $ do
          void newline
          manyTill anySingle eof

        let penBlock = maybe "" asText penBlockM
        let pens     = map parseHPen $ filter (/= "") $ splitOn "\n" $ penBlock

        return $ HostPlot left right top bottom display xLabel yLabel xMin xMax yMin yMax isAuto isLegend setup update pens

    hSliderP :: Parser Widget
    hSliderP =
      do
        void $ string "SLIDER"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- nilText
        void newline
        varName  <- text
        void newline
        min      <- text
        void newline
        max      <- text
        void newline
        default' <- nlNum
        void newline
        step     <- nlTruncNum
        void newline
        void $ text
        void newline
        units    <- nilText
        void newline
        dir      <- direction

        return $ HostSlider left right top bottom display varName min max default' units dir step

    hSwitchP :: Parser Widget
    hSwitchP =
      do
        void $ string "SWITCH"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- nilText
        void newline
        varName  <- text
        void newline
        isOff    <- binDigitChar
        void newline
        void $ text
        void newline
        void $ text

        let isOn = isOff == '0'

        return $ HostSwitch left right top bottom display varName isOn


###

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
  , forever:                isForever == "T"
  , disableUntilTicksStart: duts == '1'
  , buttonKind:             "procedure"
  , actionKey:              denil(hotkey)?.slice(0, 1)
  }

convertMainChooser = (left, top, right, bottom, bodyLines) ->
  { type: "hnwChooser", left, right, top, bottom }
# (m "display" display) <> ["variable" .= variable, "choices" .= choices, "currentChoice" .= currentChoice]

convertMainInput = (left, top, right, bottom, bodyLines) ->
  { type: "hnwInputBox", left, right, top, bottom }
# "variable" .= variable, "boxedValue" .= boxedValue]

convertMainMonitor = (left, top, right, bottom, bodyLines) ->
  { type: "hnwMonitor", left, right, top, bottom }
# "display" .= display, "source" .= ("???1" :: Text), "reporterStyle" .= ("???2" :: Text), "precision" .= precision, "fontSize" .= fontSize]

convertMainOutput = (left, top, right, bottom, bodyLines) ->
  { type: "hnwOutput", left, right, top, bottom, fontSize: parseInt(bodyLines[0]) }

convertMainPlot = (left, top, right, bottom, bodyLines) ->
  { type: "hnwPlot", left, right, top, bottom }
# "display" .= display, "xAxis" .= xAxis, "yAxis" .= yAxis, "xmin" .= xmin, "xmax" .= xmax, "ymin" .= ymin, "ymax" .= ymax, "autoPlotOn" .= autoPlotOn, "legendOn" .= legendOn, "setupCode" .= setupCode, "updateCode" .= updateCode, "pens" .= pens]

convertMainSlider = (left, top, right, bottom, bodyLines) ->
  { type: "hnwSlider", left, right, top, bottom }
# (m "display" display) <> ["variable" .= variable, "min" .= min, "max" .= max, "default" .= _default] <> (m "units" units) <> ["direction" .= direction, "step" .= step]

convertMainSwitch = (left, top, right, bottom, bodyLines) ->
  { type: "hnwSwitch", left, right, top, bottom }
# (m "display" display) <> ["variable" .= variable, "on" .= on]

convertMainLabel = (left, top, right, bottom, bodyLines) ->
  [display, fontSizeStr, colorStr, isTranspStr] = bodyLines
  fontStr = parseInt(fontSizeStr)
  color   = parseFloat(colorStr)
  { type: "hnwTextBox", left, right, top, bottom, display, color, fontSize, transparent: isTranspStr is '1' }

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

convertClientChooser = (left, top, right, bottom, bodyLines) ->
  { type: "hnwChooser", left, right, top, bottom }
# <> (m "display" display) <> ["variable" .= variable, "choices" .= choices, "currentChoice" .= currentChoice]

convertClientInput = (left, top, right, bottom, bodyLines) ->
  { type: "hnwInputBox", left, right, top, bottom }
# "variable" .= variable, "boxedValue" .= boxedValue]

convertClientMonitor = (left, top, right, bottom, bodyLines) ->
  [display, _, precisionStr] = bodyLines
  precision = parseInt(precisionStr)
  { type: "hnwMonitor", left, right, top, bottom, display, source: null, reporterStyle: "turtle-procedure", precision, fontSize: 10 }

convertClientOutput = (left, top, right, bottom, bodyLines) ->
  { type: "hnwOutput", left, right, top, bottom, fontSize: parseInt(bodyLines[0]) }

convertClientPlot = (left, top, right, bottom, bodyLines) ->
  { type: "hnwPlot", left, right, top, bottom }
# "display" .= display, "xAxis" .= xAxis, "yAxis" .= yAxis, "xmin" .= xmin, "xmax" .= xmax, "ymin" .= ymin, "ymax" .= ymax, "autoPlotOn" .= autoPlotOn, "legendOn" .= legendOn, "setupCode" .= setupCode, "updateCode" .= updateCode, "pens" .= pens]

convertClientSlider = (left, top, right, bottom, bodyLines) ->
  { type: "hnwSlider", left, right, top, bottom }
# "display" .= display, "variable" .= variable, "min" .= min, "max" .= max, "default" .= _default] <> (m "units" units) <> ["direction" .= direction, "step" .= step]

convertClientSwitch = (left, top, right, bottom, bodyLines) ->
  { type: "hnwSwitch", left, right, top, bottom }
# <> (m "display" display) <> ["variable" .= variable, "on" .= on]

convertClientLabel = (left, top, right, bottom, bodyLines) ->
  { type: "hnwTextBox", left, right, top, bottom }
# "display" .= display, "color" .= color, "fontSize" .= fontSize, "transparent" .= transparent]

convertClientView = (left, top, right, bottom, bodyLines) ->
  height = right  - left
  width  = bottom - top
  { type: "hnwView", left, right, top, bottom, height, width }

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
  { canJoinMidRun: true
  , onCursorMove:  null
  , onCursorClick: null
  , onDisconnect:  null
  , widgets:       widgetNlogo.split('\n\n').map(convertMainWidget)
  , name:          "supervisor"
  , namePlural:    "supervisors"
  , onConnect:     null
  , limit:         1
  , isSpectator:   true
  }

# (String) => Object[Any]
genClientRole = (widgetNlogo) ->
  { canJoinMidRun: true
  , onCursorMove:  null
  , onCursorClick: null
  , onDisconnect:  null
  , widgets:       widgetNlogo.split('\n\n').map(convertClientWidget)
  , name:          "student"
  , namePlural:    "students"
  , onConnect:     null
  , limit:         -1
  , isSpectator:   false
  }

# (String) => Object[Any]
window.generateHNWConfig = (nlogo) ->

  [_, widgets, _, _, _, _, _, clientWidgets, _, _, _] = nlogo.split('\n@#$#@#$#@\n')

  mainRole   = genMainRole(widgets)
  clientRole = genClientRole(clientWidgets)

  outConfig =
    { roles:     [mainRole, clientRole]
    , onIterate: ""
    , onStart:   ""
    , version:   "hnw-alpha-1"
    , type:      "hubnet-web"
    }

  debugger

  outConfig


###

    jChooserP :: Parser Widget
    jChooserP =
      do
        void $ string "CHOOSER"
        void newline
        left      <- nlInt
        void newline
        top       <- nlInt
        void newline
        right     <- nlInt
        void newline
        bottom    <- nlInt
        void newline
        display   <- nilText
        void newline
        varName   <- text
        void newline
        choiceStr <- text
        void newline
        defIndex  <- nlInt

        let choices = mungeChoices choiceStr

        return $ ClientChooser left right top bottom display varName choices defIndex

    jInputP :: Parser Widget
    jInputP =
      do
        void $ string "INPUTBOX"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        varName  <- text
        void newline
        default' <- text
        void newline
        isMu     <- binDigitChar
        void newline
        void $ text
        void newline
        type' <- text

        let isMulti    = isMu == '1'
        let inputValue = genInputValue default' isMulti type'

        return $ ClientInputBox left right top bottom varName inputValue

    jPlotP :: Parser Widget
    jPlotP =
      do
        void $ string "PLOT"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- text
        void newline
        xLabel   <- text
        void newline
        yLabel   <- text
        void newline
        xMin     <- nlNum
        void newline
        xMax     <- nlNum
        void newline
        yMin     <- nlNum
        void newline
        yMax     <- nlNum
        void newline
        isAuto   <- bool
        void newline
        isLegend <- bool
        void newline
        setup    <- stringLiteral
        void $ string " "
        update   <- stringLiteral
        void newline
        void $ string "PENS"
        penBlockM <- optional . try $ do
          void newline
          manyTill anySingle eof

        let penBlock = maybe "" asText penBlockM
        let pens     = map parseJPen $ filter (/= "") $ splitOn "\n" $ penBlock

        return $ ClientPlot left right top bottom display xLabel yLabel xMin xMax yMin yMax isAuto isLegend setup update pens

    jSliderP :: Parser Widget
    jSliderP =
      do
        void $ string "SLIDER"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- text
        void newline
        varName  <- text
        void newline
        min      <- text
        void newline
        max      <- text
        void newline
        default' <- nlNum
        void newline
        step     <- nlNum
        void newline
        void $ text
        void newline
        units    <- nilText
        void newline
        dir      <- direction

        return $ ClientSlider left right top bottom display varName min max default' units dir step

    jSwitchP :: Parser Widget
    jSwitchP =
      do
        void $ string "SWITCH"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- nilText
        void newline
        varName  <- text
        void newline
        isOff    <- binDigitChar
        void newline
        void $ text
        void newline
        void $ text

        let isOn = isOff == '0'

        return $ ClientSwitch left right top bottom display varName isOn

    jTextP :: Parser Widget
    jTextP =
      do
        void $ string "TEXTBOX"
        void newline
        left     <- nlInt
        void newline
        top      <- nlInt
        void newline
        right    <- nlInt
        void newline
        bottom   <- nlInt
        void newline
        display  <- text
        void newline
        fontSize <- nlInt
        void newline
        color    <- nlNum
        void newline
        isTransp <- binDigitChar

        let isTransparent = isTransp == '1'

        return $ ClientTextbox left right top bottom display color fontSize isTransparent

parseHPen :: Text -> HostPen
parseHPen = ((parseMaybe hPenParser) &> (maybe (error "Penboom") id))

hPenParser :: Parser HostPen
hPenParser =
  do
    name     <- stringLiteral
    void $ string " "
    interval <- nlNum
    void $ string " "
    mode     <- nlInt
    void $ string " "
    color    <- nlNum
    void $ string " "
    sil      <- bool
    void $ string " "
    setup    <- stringLiteral
    void $ string " "
    update   <- stringLiteral

    return $ HostPen name interval mode color sil setup update

parseJPen :: Text -> ClientPen
parseJPen = ((parseMaybe jPenParser) &> (maybe (error "Penboom") id))

jPenParser :: Parser ClientPen
jPenParser =
  do
    name     <- stringLiteral
    void $ string " "
    interval <- nlNum
    void $ string " "
    mode     <- nlInt
    void $ string " "
    color    <- nlNum
    void $ string " "
    sil      <- bool
    void $ string " "
    setup    <- stringLiteral
    void $ string " "
    update   <- stringLiteral

    return $ ClientPen name interval mode color sil setup update

mungeChoices :: Text -> Text
mungeChoices = T.replace " " ", "

textToDir :: Text -> SliderDirection
textToDir "HORIZONTAL" = Horizontal
textToDir "VERTICAL"   = Vertical
textToDir x            = error $ "You did wot, mate?  " <> x

textToButtonKind :: Text -> ButtonKind
textToButtonKind "LINK"     = LinkButton
textToButtonKind "OBSERVER" = ObserverButton
textToButtonKind "PATCH"    = PatchButton
textToButtonKind "TURTLE"   = TurtleButton
textToButtonKind x          = error $ "That really isn't a button kind: " <> x

genInputValue :: Text -> Bool -> Text -> SuperBoxedValue
genInputValue default' isMulti typ@"Color"             = SuperBoxedValue typ isMulti $ BoxedDouble (unsafeTextDouble default')
genInputValue default' isMulti typ@"Number"            = SuperBoxedValue typ isMulti $ BoxedDouble (unsafeTextDouble default')
genInputValue default' isMulti typ@"String"            = SuperBoxedValue typ isMulti $ BoxedString                   default'
genInputValue default' isMulti typ@"String (commands)" = SuperBoxedValue typ isMulti $ BoxedString                   default'
genInputValue default' isMulti typ@"String (reporter)" = SuperBoxedValue typ isMulti $ BoxedString                   default'
genInputValue _        _       typ                     = error $ "You've done one of the bad things: " <> typ

nlInt :: Parser Int
nlInt = signed (return ()) decimal

nlNum :: Parser Double
nlNum = (signed (return ()) scientific) <&> toRealFloat

nlTruncNum :: Parser Double
nlTruncNum = nlNum <|> ((char '.' *> decimal) <&> fractionalize)
  where
    fractionalize x =
      if x <= 0 then
        x
      else
        fractionalize $ x / 10

bool :: Parser Bool
bool = ((string "false") <|> (string "true")) <&> (== "true")

text :: Parser Text
text = (some printChar) <&> asText

nilText :: Parser (Maybe Text)
nilText = text <&> (\x -> if x == "NIL" then Nothing else Just x)

stringLiteral :: Parser Text
stringLiteral = (char '\"' *> manyTill charLiteral (char '\"')) <&> asText

direction :: Parser SliderDirection
direction = (string "HORIZONTAL" <|> string "VERTICAL") <&> textToDir

unsafeTextDouble :: Text -> Double
unsafeTextDouble = TRead.rational &> (either (error "get wrecked") id) &> fst
###
