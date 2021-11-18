# (Ractive) => OutputWidget?
getOutputWidget = (ractive) ->
  ractive.findComponent('outputWidget') ? ractive.findComponent('hnwOutputWidget')

# (String, Ractive) => ((String) => Unit) => Unit
importFile = (type, ractive) -> (callback) ->

  listener =
    (event) ->
      reader = new FileReader
      reader.onload = (e) -> callback(e.target.result)
      if event.target.files.length > 0
        file = event.target.files[0]
        if type is "image" or (type is "any" and file.type.startsWith("image/"))
          reader.readAsDataURL(file)
        else
          reader.readAsText(file)
      elem.removeEventListener('change', listener)

  elem = ractive.find('#general-file-input')
  elem.addEventListener('change', listener)
  elem.click()
  elem.value = ""

  return

# (Ractive, ViewController) => AsyncDialogConfig
genAsyncDialogConfig = (ractive, viewController) ->

  clearMouse = ->
    viewController.mouseDown = false
    return

  tellDialog = (eventName, args...) ->
    ractive.findComponent('asyncDialog').fire(eventName, args...)

  {

    getChoice: (message, choices) -> (callback) ->
      clearMouse()
      tellDialog('show-chooser', message, choices, callback)
      return

    getText: (message) -> (callback) ->
      clearMouse()
      tellDialog('show-text-input', message, callback)
      return

    getYesOrNo: (message) -> (callback) ->
      clearMouse()
      tellDialog('show-yes-or-no', message, callback)
      return

    showMessage: (message) -> (callback) ->
      clearMouse()
      tellDialog('show-message', message, callback)
      return

  }

# (ViewController) => DialogConfig
genDialogConfig = (viewController) ->

  clearMouse = ->
    viewController.mouseDown = false
    return

  # `yesOrNo` should eventually be changed to use a proper synchronous, three-button,
  # customizable dialog... when HTML and JS start to support that. --JAB (6/1/16)
  #
  # Uhh, they probably never will.  Instead, we should favor the `dialog` extension,
  # for which we provide "asyncDialog" shims above. --JAB (4/5/19)
  {
    confirm: (str) -> clearMouse(); window.confirm(str)
    input:   (str) -> clearMouse(); window.prompt(str, "")
    notify:  (str) -> clearMouse(); window.nlwAlerter.display("NetLogo Notification", true, str)
    yesOrNo: (str) -> clearMouse(); window.confirm(str)
  }

# (Ractive, ViewController) => ImportExportConfig
genImportExportConfig = (ractive, viewController) ->
  {

    exportFile: (contents) -> (filename) ->
      window.saveAs(new Blob([contents], {type: "text/plain:charset=utf-8"}), filename)
      return

    exportBlob: (blob) -> (filename) ->
      window.saveAs(blob, filename)

    getNlogo: ->

      { result, success } =
        (new BrowserCompiler()).exportNlogo({
          info:         Tortoise.toNetLogoMarkdown(ractive.get('info')),
          code:         ractive.get('code'),
          widgets:      (v for _, v of ractive.get('widgetObj')),
          turtleShapes: turtleShapes,
          linkShapes:   linkShapes
        })

      if success
        result
      else
        throw new Error("The current model could not be converted to 'nlogo' format")

    getOutput: ->
      getOutputWidget(ractive).get('text') ? ractive.findComponent('console').get('output')

    getViewBase64: ->
      viewController.view.visibleCanvas.toDataURL("image/png")

    getViewBlob: (callback) ->
      viewController.view.visibleCanvas.toBlob(callback, "image/png")

    importFile: (path) -> (callback) ->
      importFile("any", ractive)(callback)
      return

    importModel: (nlogoContents, modelName) ->
      window.postMessage({
        nlogo: nlogoContents
      ,  path: modelName
      ,  type: "nlw-load-model"
      }, "*")
      return

  }

# () => InspectionConfig
genInspectionConfig = ->
  inspect        = ((agent) -> window.alert("Agent inspection is not yet implemented"))
  stopInspecting = ((agent) ->)
  clearDead      = (->)
  { inspect, stopInspecting, clearDead }

# (Ractive) => IOConfig
genIOConfig = (ractive) ->
  {

    importFile: (filepath) -> (callback) ->
      console.warn("Unsupported operation: `importFile`")
      return

    slurpFileDialogAsync: (callback) ->
      importFile("any", ractive)(callback)
      return

    slurpURL: (url) ->

      req = new XMLHttpRequest()

      # Setting the async option to `false` is deprecated and "bad" as far as HTML/JS is
      # concerned.  But this is NetLogo and NetLogo model code doesn't have a concept of
      # async execution, so this is the best we can do.  As long as it isn't used on a
      # per-tick basis or in a loop, it should be okay.  -JMB August 2017, JAB (10/25/18)
      req.open("GET", url, false)
      req.overrideMimeType('text\/plain; charset=x-user-defined') # Get as binary string -- JAB (10/27/18)
      req.send()

      response    = req.response
      contentType = req.getResponseHeader("content-type")

      if contentType.startsWith("image/")
        combine = (acc, i) -> acc + String.fromCharCode(response.charCodeAt(i) & 0xff)
        uint8Str = [0...response.length].reduce(combine, "")
        "data:#{contentType};base64,#{btoa(uint8Str)}"
      else
        response

    slurpURLAsync: (url) -> (callback) ->
      fetch(url).then(
        (response) ->
          if response.headers.get("content-type").startsWith("image/")
            response.blob().then(
              (blob) ->
                reader = new FileReader
                reader.onload = (e) -> callback(e.target.result)
                reader.readAsDataURL(blob)
            )
          else
            response.text().then(callback)
      )
      return

  }

# (ViewController) => MouseConfig
genMouseConfig = (viewController) ->
  {
    peekIsDown:   -> viewController.mouseDown
    peekIsInside: -> viewController.mouseInside
    peekX:           viewController.mouseXcor
    peekY:           viewController.mouseYcor
  }

# (Element, Ractive) => Object[HighchartsOps]
genPlotOps = (container, ractive) ->
  widgets = Object.values(ractive.get('widgetObj'))
  plotOps = {}
  for widget in widgets when widget.type in ["plot", "hnwPlot"]

    { display, id, legendOn, type, xAxis, xmax, xmin, yAxis, ymax, ymin } = widget

    pops             = new HighchartsOps(container.querySelector("#netlogo-#{type}-#{id}"))
    plotOps[display] = pops

    if type is "hnwPlot"

      mockPlot = { isLegendEnabled: legendOn
                 , name:            display
                 , xLabel:          xAxis
                 , yLabel:          yAxis
                 }

      pops.reset(mockPlot)
      pops.resize(xmin, xmax, ymin, ymax)

      for _, pen of widget.pens

        numToMode = (num) ->
          { Bar, Line, Point } = tortoise_require('engine/plot/pen').DisplayMode
          modeObj =
            switch num
              when 0 then Line
              when 1 then Bar
              when 2 then Point
              else        Line

        # (Number) => Number
        javaColorToNetLogo = (c) ->

          componentToHex = (comp) -> Number(comp).toString(16).padStart(2, '0')
          f              = componentToHex

          r = (c & 0xFF0000) >> 16
          g = (c & 0x00FF00) >>  8
          b = (c & 0x0000FF)

          hexStringToNetlogoColor("##{f(r)}#{f(g)}#{f(b)}")

        mockPen = { name:               pen.display
                  , getColor:       (-> javaColorToNetLogo(pen.color))
                  , getDisplayMode: (-> numToMode(pen.mode))
                  }

        pops.resetPen(mockPen)
        pops.updatePenMode(mockPen, numToMode(pen.mode))
        pops.registerPen(mockPen)

  plotOps

# (Ractive, (String) => Unit) => OutputConfig
genOutputConfig = (ractive, appendToConsole) ->
  {
    clear:
      ->
        output = getOutputWidget(ractive)
        if (output?) then output.setText('')
    write:
      (str) ->
        output = getOutputWidget(ractive)
        if (output?)
          output.appendText(str)
        else
          appendToConsole(str)
  }

# (Ractive) => WorldConfig
genWorldConfig = (ractive) ->
  {
    resizeWorld: ->
      checkIsForever        = ({ type, forever, running }) -> type in ["button", "hnwButton"] and forever and running
      widgets               = Object.values(ractive.get('widgetObj'))
      runningForeverButtons = widgets.filter(checkIsForever)
      runningForeverButtons.forEach((button) -> button.running = false)
      return
  }

# (Ractive, ViewController, Element) => Configs
window.genConfigs = (ractive, viewController, container) ->

  appendToConsole = (str) ->
    ractive.set('consoleOutput', ractive.get('consoleOutput') + str)

  { asyncDialog:       genAsyncDialogConfig(ractive, viewController)
  , base64ToImageData: window.synchroDecoder
  , dialog:            genDialogConfig(viewController)
  , importExport:      genImportExportConfig(ractive, viewController)
  , inspection:        genInspectionConfig()
  , io:                genIOConfig(ractive)
  , mouse:             genMouseConfig(viewController)
  , output:            genOutputConfig(ractive, appendToConsole)
  , print:             { write: appendToConsole }
  , plotOps:           genPlotOps(container, ractive)
  , world:             genWorldConfig(ractive)
  }
