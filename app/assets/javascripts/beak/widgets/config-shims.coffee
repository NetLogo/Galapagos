# (ViewController) => DialogConfig
genDialogConfig = (viewController) ->

  clearMouse = ->
    viewController.mouseDown = false
    return

  # `yesOrNo` should eventually be changed to use a proper synchronous, three-button,
  # customizable dialog... when HTML and JS start to support that. --JAB (6/1/16)
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

    exportOutput: (filename) ->
      exportText = ractive.findComponent('outputWidget')?.get('text') ? ractive.findComponent('console').get('output')
      exportBlob = new Blob([exportText], {type: "text/plain:charset=utf-8"})
      window.saveAs(exportBlob, filename)
      return

    exportView: (filename) ->
      anchor = document.createElement("a")
      anchor.setAttribute("href", viewController.view.visibleCanvas.toDataURL("img/png"))
      anchor.setAttribute("download", filename)
      anchor.click()
      return

    importDrawing: (trueImport) -> (path) ->

      listener =
        (event) ->
          reader = new FileReader
          reader.onload = (e) -> trueImport(e.target.result)
          if event.target.files.length > 0
            reader.readAsDataURL(event.target.files[0])
          elem.removeEventListener('change', listener)

      elem = ractive.find('#import-drawing-input')
      elem.addEventListener('change', listener)
      elem.click()
      elem.value = ""

      return

    importWorld: (trueImport) -> ->

      listener =
        (event) ->
          reader = new FileReader
          reader.onload = (e) -> trueImport(e.target.result)
          if event.target.files.length > 0
            reader.readAsText(event.target.files[0])
          elem.removeEventListener('change', listener)

      elem = ractive.find('#import-world-input')
      elem.addEventListener('change', listener)
      elem.click()
      elem.value = ""

      return

  }

# () => InspectionConfig
genInspectionConfig = ->
  inspect        = ((agent) -> window.alert("Agent inspection is not yet implemented"))
  stopInspecting = ((agent) ->)
  clearDead      = (->)
  { inspect, stopInspecting, clearDead }

# (ViewController) => MouseConfig
genMouseConfig = (viewController) ->
  {
    peekIsDown:   -> viewController.mouseDown
    peekIsInside: -> viewController.mouseInside
    peekX:           viewController.mouseXcor
    peekY:           viewController.mouseYcor
  }

# (Element, Ractive) => [HighchartsOps]
genPlotOps = (container, ractive) ->
  widgets = Object.values(ractive.get('widgetObj'))
  plotOps = {}
  for { display, id, type } in widgets when type is "plot"
    plotOps[display] = new HighchartsOps(container.querySelector("#netlogo-plot-#{id}"))
  plotOps

# (Ractive, (String) => Unit) => OutputConfig
genOutputConfig = (ractive, appendToConsole) ->
  {
    clear:
      ->
        output = ractive.findComponent('outputWidget')
        if (output?) then output.setText('')
    write:
      (str) ->
        output = ractive.findComponent('outputWidget')
        if (output?)
          output.appendText(str)
        else
          appendToConsole(str)
  }

# (Ractive) => WorldConfig
genWorldConfig = (ractive) ->
  {
    resizeWorld: ->
      widgets               = Object.values(ractive.get('widgetObj'))
      runningForeverButtons = widgets.filter(({ type, forever, running }) -> type is "button" and forever and running)
      runningForeverButtons.forEach((button) -> button.running = false)
      return
  }

# (Ractive, ViewController, Element) => Configs
window.genConfigs = (ractive, viewController, container) ->

  appendToConsole = (str) ->
    ractive.set('consoleOutput', ractive.get('consoleOutput') + str)

  {
    dialog:       genDialogConfig(viewController)
  , importExport: genImportExportConfig(ractive, viewController)
  , inspection:   genInspectionConfig()
  , mouse:        genMouseConfig(viewController)
  , output:       genOutputConfig(ractive, appendToConsole)
  , print:        { write: appendToConsole }
  , plotOps:      genPlotOps(container, ractive)
  , world:        genWorldConfig(ractive)
  }

