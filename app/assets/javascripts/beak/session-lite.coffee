MAX_UPDATE_DELAY     = 1000
FAST_UPDATE_EXP      = 0.5
SLOW_UPDATE_EXP      = 4
MAX_UPDATE_TIME      = 100

DEFAULT_REDRAW_DELAY = 1000 / 30
MAX_REDRAW_DELAY     = 1000
REDRAW_EXP           = 2

NETLOGO_VERSION      = '2.5.2'

# performance.now gives submillisecond timing, which improves the event loop
# for models with submillisecond go procedures. Unfortunately, iOS Safari
# doesn't support it. BCH 10/3/2014
now = performance?.now.bind(performance) ? Date.now.bind(Date)

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

window.AgentModel = tortoise_require('agentmodel')
agentToInt        = tortoise_require('engine/core/agenttoint')

class window.SessionLite

  # type HNWUpdate       = { widgetUpdates : Array[WidgetUpdate], monitorUpdates : Object[String], plotUpdates : Object[Array[Object[Any]]], viewUpdate : Array[ViewUpdate] }
  # type SparseHNWUpdate = { widgetUpdates?: Array[WidgetUpdate], monitorUpdates?: Object[String], plotUpdates?: Object[Array[Object[Any]]], viewUpdate?: Array[ViewUpdate] }
  # type PlotsUpdate     = Object[Array[Object[Any]]]

  widgetController: undefined # WidgetController

  _hnwTargetFPS:         undefined # Number
  _hnwLastPersp:         undefined # Object[(String, Agent, Number)]
  _hnwLastLoopTS:        undefined # Number
  _hnwLastTickTS:        undefined # Number
  _hnwImageCache:        undefined # Object[Object[String]]
  _hnwIsCongested:       undefined # Boolean
  _hnwWidgetGlobalCache: undefined # Object[Any]

  _metadata:             undefined # Object[Any]
  _monitorFuncs:         undefined # Object[((Number) => String, Object[String])]
  _subscriberObj:        undefined # Object[Window]
  _lastBCastTicks:       undefined # Number

  # (Element|String, Array[Widget], String, String, Boolean, String, String, Boolean, BrowserCompiler, (String) => Unit)
  constructor: (container, widgets, code, info, readOnly, filename, modelJS, lastCompileFailed, @compiler, @displayError) ->

    @_hnwLastPersp         = {}
    @_hnwImageCache        = {}
    @_hnwWidgetGlobalCache = {}
    @_monitorFuncs         = {}
    @_subscriberObj        = {}

    @_hnwIsCongested = false
    @_hnwTargetFPS   = 20

    @_metadata =
      { globalVars: []
      , myVars:     []
      , procedures: []
      }

    checkIsReporter = (str) => @compiler.isReporter(str)

    @_eventLoopTimeout = -1
    @_lastRedraw       = 0
    @_lastUpdate       = 0
    @drawEveryFrame    = false

    @widgetController =
      initializeUI(container, widgets, code, info, readOnly, filename, checkIsReporter, (=> @_performUpdate()))

    @widgetController.ractive.on('*.recompile'     , (_, callback)       => @recompile(callback))
    @widgetController.ractive.on('*.recompile-lite', (_, callback)       => @recompileLite(callback))
    @widgetController.ractive.on('export-nlogo'    , (_, event)          => @exportNlogo(event))
    @widgetController.ractive.on('export-html'     , (_, event)          => @exportHtml(event))
    @widgetController.ractive.on('open-new-file'   , (_, event)          => @openNewFile())
    @widgetController.ractive.on('console.run'     , (_, code, errorLog) => @run(code, errorLog))
    @widgetController.ractive.set('lastCompileFailed', lastCompileFailed)

    window.modelConfig         = Object.assign(window.modelConfig ? {}, @widgetController.configs)
    window.modelConfig.version = NETLOGO_VERSION
    globalEval(modelJS)

  modelTitle: ->
    @widgetController.ractive.get('modelTitle')

  startLoop: ->
    @_performUpdate()
    @widgetController.updateWidgets()
    requestAnimationFrame(@eventLoop)

    thunk =
      =>
        if workspace?
          pp = workspace.procedurePrims
          if pp.hasCommand('startup')
            window.runWithErrorHandling('startup', @widgetController.reportError, () -> pp.callCommand('startup'))
        else
          setTimeout(thunk, 5)

    thunk()

  calcNumUpdates: ->

    twoThirdsian = (xs) ->
      sorted = xs.sort()
      if sorted.length is 0
        undefined
      else if sorted.length is 1
        sorted[0]
      else if sorted.length is 2
        (2 * (sorted[0] + sorted[1])) / 3
      else if sorted.length is 3
        (sorted[1] + sorted[2]) / 2
      else
        twoThirdsian(sorted.slice(2, sorted.length - 1))

    standardCalc = =>
      if @drawEveryFrame then 1 else (now() - @_lastUpdate) / @updateDelay()

    if window.isHNWHost is true

      pings              = Object.values(window.clients).map((c) -> c.ping).filter((p) -> p?)
      representativePing = twoThirdsian(pings)

      document.getElementById("hnw-typical-ping").innerText = Math.round(representativePing ? 0)
      maxTypicalPing = document.getElementById("hnw-max-typical-ping").value

      if representativePing > maxTypicalPing
        0
      else if @drawEveryFrame
        1
      else
        (now() - @_lastUpdate) / (1000 / @_hnwTargetFPS)
    else
      standardCalc()

  updateDelay: ->

    viewWidget = @widgetController.widgets().find((w) -> w.type is 'view' or w.type is 'hnwView')
    speed      = @widgetController.speed()
    delay      = 1000 / viewWidget.frameRate

    if speed > 0
      speedFactor = Math.pow(Math.abs(speed), FAST_UPDATE_EXP)
      delay * (1 - speedFactor)
    else
      speedFactor = Math.pow(Math.abs(speed), SLOW_UPDATE_EXP)
      MAX_UPDATE_DELAY * speedFactor + delay * (1 - speedFactor)

  redrawDelay: ->
    speed = @widgetController.speed()
    if speed > 0
      speedFactor = Math.pow(Math.abs(@widgetController.speed()), REDRAW_EXP)
      MAX_REDRAW_DELAY * speedFactor + DEFAULT_REDRAW_DELAY * (1 - speedFactor)
    else
      DEFAULT_REDRAW_DELAY

  eventLoop: (timestamp) =>

    time               = now()
    @_eventLoopTimeout = requestAnimationFrame(@eventLoop)
    updatesDeadline    = Math.min(@_lastRedraw + @redrawDelay(), time + MAX_UPDATE_TIME)
    maxNumUpdates      = @calcNumUpdates()

    hnwLoopElapsed    = time - (@_hnwLastLoopTS ? 0)
    hnwTickElapsed    = time - (@_hnwLastTickTS ? 0)
    hnwTargetInterval = 1000 / @_hnwTargetFPS
    hnwLoopInterval   = 1000 / 20

    if (not @_hnwLastLoopTS?) or (hnwLoopElapsed > hnwLoopInterval)

      if window.isHNWHost is true
        @_hnwLastLoopTS = time

      if (not @_hnwLastTickTS?) or ((not @_hnwIsCongested) and (hnwTickElapsed > hnwTargetInterval))
        if not @widgetController.ractive.get('isEditing')
          if window.isHNWHost is true
            @_hnwLastTickTS = time
          for i in [1..maxNumUpdates] by 1 # maxNumUpdates can be 0. Need to guarantee i is ascending.
            @_lastUpdate = now()
            @widgetController.runForevers()
            if document.getElementById('hnw-go')?.checked
              window.hnwGoProc()
            if now() >= updatesDeadline
              break

      if Updater.hasUpdates()
        # First conditional checks if we're on time with updates. If so, we may as
        # well redraw. This keeps animations smooth for fast models. BCH 11/4/2014
        if i > maxNumUpdates or now() - @_lastRedraw > @redrawDelay() or @drawEveryFrame
          @_lastRedraw = now()
          @_performUpdate(true)
        else
          @_performUpdate(false)
      else
        @_performUpdate(false)


      # Widgets must always be updated, because global variables and plots can be
      # altered without triggering an "update".  That is to say that `Updater`
      # only concerns itself with View updates. --JAB (9/2/15)
      @widgetController.updateWidgets()

  teardown: ->
    @widgetController.teardown()
    cancelAnimationFrame(@_eventLoopTimeout)

  # (() => Unit) => Unit
  recompileLite: (successCallback = (->)) ->
    lastCompileFailed   = @widgetController.ractive.get('lastCompileFailed')
    someWidgetIsFailing = @widgetController.widgets().some((w) -> w.compilation?.success is false)
    if lastCompileFailed or someWidgetIsFailing
      @recompile(successCallback)
    return

  # (() => Unit) => Unit
  recompile: (successCallback = (->)) ->

    if @widgetController.ractive.get('isEditing') and @widgetController.ractive.get('isHNW')
      parent.postMessage({ type: "recompile" }, "*")
    else

      code       = @widgetController.code()
      oldWidgets = @widgetController.widgets()

      onCompile =
        (res) =>

          if res.model.success

            state = world.exportState()
            breedShapePairs = world.breedManager.breeds().map((b) -> [b.name, b.getShape()])
            world.clearAll()
            @_performUpdate(true) # Redraw right before `Updater` gets clobbered --JAB (2/27/18)

            widgets = Object.values(@widgetController.ractive.get('widgetObj'))
            pops    = @widgetController.configs.plotOps
            ractive = @widgetController.ractive
            for { display, id, type } in widgets when type in ["plot", "hnwPlot"]
              pops[display]?.dispose()
              hops          = new HighchartsOps(ractive.find("#netlogo-#{type}-#{id}"))
              pops[display] = hops
              normies       = ractive.findAllComponents("plotWidget")
              hnws          = ractive.findAllComponents("hnwPlotWidget")
              component     = [].concat(normies, hnws).find((plot) -> plot.get("widget").display is display)
              component.set('resizeCallback', hops.resizeElem.bind(hops))
              hops._chart.chartBackground.css({ color: '#efefef' })

            globalEval(res.model.result)
            breedShapePairs.forEach(([name, shape]) -> world.breedManager.get(name).setShape(shape))
            world.importState(state)

            @widgetController.ractive.set('isStale',           false)
            @widgetController.ractive.set('lastCompiledCode',  code)
            @widgetController.ractive.set('lastCompileFailed', false)
            @_performUpdate(true)
            @widgetController.freshenUpWidgets(oldWidgets, globalEval(res.widgets))

            for pop in pops
              pop._chart.chartBackground.css({ color: '#efefef' })

            successCallback()

          else
            @widgetController.ractive.set('lastCompileFailed', true)
            res.model.result.forEach( (r) => r.lineNumber = code.slice(0, r.start).split("\n").length )
            @alertCompileError(res.model.result)

      Tortoise.startLoading(=> @_codeCompile(code, [], [], oldWidgets, onCompile, @alertCompileError))

  getNlogo: ->
    @compiler.exportNlogo({
      info:         Tortoise.toNetLogoMarkdown(@widgetController.ractive.get('info')),
      code:         @widgetController.ractive.get('code'),
      widgets:      @widgetController.widgets(),
      turtleShapes: turtleShapes,
      linkShapes:   linkShapes
    })

  exportNlogo: ->
    exportName = @promptFilename(".nlogo")
    if exportName?
      exportedNLogo = @getNlogo()
      if (exportedNLogo.success)
        exportBlob = new Blob([exportedNLogo.result], {type: "text/plain:charset=utf-8"})
        saveAs(exportBlob, exportName)
      else
        @alertCompileError(exportedNLogo.result)

  promptFilename: (extension) =>
    suggestion = @modelTitle() + extension
    window.prompt('Filename:', suggestion)

  exportHtml: ->
    exportName = @promptFilename(".html")
    if exportName?
      window.req = new XMLHttpRequest()
      req.open('GET', standaloneURL)
      req.onreadystatechange = =>
        if req.readyState is req.DONE
          if req.status is 200
            nlogo = @getNlogo()
            if nlogo.success
              parser = new DOMParser()
              dom = parser.parseFromString(req.responseText, "text/html")
              nlogoScript = dom.querySelector("#nlogo-code")
              nlogoScript.textContent = nlogo.result
              nlogoScript.dataset.filename = exportName.replace(/\.html$/, ".nlogo")
              wrapper = document.createElement("div")
              wrapper.appendChild(dom.documentElement)
              exportBlob = new Blob([wrapper.innerHTML], {type: "text/html:charset=utf-8"})
              saveAs(exportBlob, exportName)
            else
              @alertCompileError(nlogo.result)
          else
            alert("Couldn't get standalone page")
      req.send("")

  # () => Unit
  openNewFile: ->

    if confirm('Are you sure you want to open a new model?  You will lose any changes that you have not exported.')

      parent.postMessage({
        hash: "NewModel",
        type: "nlw-set-hash"
      }, "*")

      window.postMessage({
        type: "nlw-open-new"
      }, "*")

    return

  # (Object[Any], ([{ config: Object[Any], results: Object[Array[Any]] }]) => Unit) => Unit
  asyncRunBabyBehaviorSpace: (config, reaction) ->
    Tortoise.startLoading(=>
      reaction(@runBabyBehaviorSpace(config))
      Tortoise.finishLoading()
    )

  # (Object[Any]) => [{ config: Object[Any], results: Object[Array[Any]] }]
  runBabyBehaviorSpace: ({ experimentName, parameterSet, repetitionsPerCombo, metrics, setupCode, goCode
                         , stopConditionCode, iterationLimit }) ->

    { last, map, toObject, zip } = tortoise_require('brazier/array')
    { pipeline                 } = tortoise_require('brazier/function')

    result = @compiler.fromModel({ code: @widgetController.code(), widgets: @widgetController.widgets()
                                 , commands: [setupCode, goCode]
                                 , reporters: metrics.map((m) -> m.reporter).concat([stopConditionCode])
                                 , turtleShapes: [], linkShapes: []
                                 })

    unwrapCompilation =
      (prefix, defaultCode) -> ({ result: compiledCode, success }) ->
        new Function("#{prefix}#{if success then compiledCode else defaultCode}")

    [setup, go]      = result.commands .map(unwrapCompilation(""       , ""  ))
    [metricFs..., _] = result.reporters.map(unwrapCompilation("return ", "-1"))
    stopCondition    = unwrapCompilation("return ", "false")(last(result.reporters))

    convert = ([{ reporter, interval }, f]) -> [reporter, { reporter: f, interval }]
    compiledMetrics = pipeline(zip(metrics), map(convert), toObject)(metricFs)

    massagedConfig = { experimentName, parameterSet, repetitionsPerCombo, metrics: compiledMetrics
                     , setup, go, stopCondition, iterationLimit }
    setGlobal      = world.observer.setGlobal.bind(world.observer)

    miniDump = (x) ->
      if Array.isArray(x)
        x.map(miniDump)
      else if typeof(x) in ["boolean", "number", "string"]
        x
      else
        workspace.dump(x)

    window.runBabyBehaviorSpace(massagedConfig, setGlobal, miniDump)

  # (String, (Array[String]) => Unit) => Unit
  run: (code, errorLog) ->

    compileErrorLog = (result) => @alertCompileError(result, errorLog)

    Tortoise.startLoading()
    @_codeCompile(@widgetController.code(), [code], [], @widgetController.widgets(),
      ({ commands, model: { result: modelResult, success: modelSuccess } }) =>
        if modelSuccess
          [{ result, success }] = commands
          if (success)
            try window.handlingErrors(new Function(result))(errorLog)
            catch ex
              if not (ex instanceof Exception.HaltInterrupt)
                throw ex
          else
            compileErrorLog(result)
        else
          compileErrorLog(modelResult)
    , compileErrorLog)

  # (String, (String, Array[{ message: String}]) => String) =>
  #  { success: true, value: Any } | { success: false, error: String }
  runReporter: (code, errorLog) ->
    errorLog = errorLog ? (prefix, errs) ->
      message = "#{prefix}: #{errs.map((err) -> err.message)}"
      console.error(message)
      message

    compileParams = {
      code:         @widgetController.code(),
      widgets:      @widgetController.widgets(),
      commands:     [],
      reporters:    [code],
      turtleShapes: turtleShapes ? [],
      linkShapes:   linkShapes ? []
    }
    compileResult = @compiler.fromModel(compileParams)

    { reporters, model: { result: modelResult, success: modelSuccess } } = compileResult
    if not modelSuccess
      message = errorLog("Compiler error", modelResult)
      return { success: false, error: message }

    [{ result, success }] = reporters
    if not success
      message = errorLog("Reporter error", result)
      return { success: false, error: message }

    reporter = new Function("return ( #{result} );")
    return try
      reporterValue = reporter()
      { success: true, value: reporterValue }
    catch ex
      message = errorLog("Runtime error", [ex])
      { success: false, error: message }

  alertCompileError: (result, errorLog = @alertErrors) ->
    errorLog(result.map((err) -> if err.lineNumber? then "(Line #{err.lineNumber}) #{err.message}" else err.message))

  alertErrors: (messages) =>
    @displayError(messages.join('\n'))

  _codeCompile: (code, commands, reporters, widgets, onFulfilled, onErrors) ->
    compileParams = {
      code:         code,
      widgets:      widgets,
      commands:     commands,
      reporters:    reporters,
      turtleShapes: turtleShapes ? [],
      linkShapes:   linkShapes ? []
    }
    try
      res = @compiler.fromModel(compileParams)
      @_updateMetadata(code, globalEval(res.widgets))
      onFulfilled(res)
    catch ex
      onErrors([ex])
    finally
      Tortoise.finishLoading()

  # (Window) => Unit
  subscribe: (wind) ->

    genUUID = ->

      replacer =
        (c) ->
          r = Math.random() * 16 | 0
          v = if c == 'x' then r else (r & 0x3 | 0x8)
          v.toString(16)

      'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, replacer)

    @_subscriberObj[genUUID()] = wind

    return

  # (Window, String) => Unit
  subscribeWithID: (wind, id) ->
    @_subscriberObj[id] = wind
    return

  # (String) => Unit
  unsubscribe: (id) ->
    delete @_subscriberObj[id]
    return

  # (String) => { widgetUpdates: Object[Array[WidgetUpdate]], plotUpdates: Object[Any], viewUpdate: Update }
  getModelState: (myRole) ->
    { drawingEvents, links, observer, patches, turtles, world: w } = @widgetController.viewController.model
    devs          = @_handleImageCache(drawingEvents)
    viewUpdate    = { drawingEvents: devs, links, observer: { 0: observer }, patches, turtles, world: { 0: w } }
    widgetUpdates = if myRole is "" then @_genWidgetUpdates() else { [myRole]: @_getWidgetUpdates(@widgetController.widgets()) }
    plotUpdates   = @widgetController.getPlotUpdates()
    { widgetUpdates, plotUpdates, viewUpdate }

  # () => Array[Object[WidgetUpdate]]
  _genWidgetUpdates: ->

    #hnwVars = world.observer.varNames().filter((x) -> x.startsWith("__hnw_"))

    #objects =
    #  hnwVars.map(
    #    (x) ->
    #      matches = /__hnw_([^_]*)_(.*)/.exec(x)
    #      { fullName: matches[0], roleName: matches[1], shortName: matches[2] }
    #  )

    #objects.reduce(
    #  (acc, { fullName, roleName, shortName }) ->
    #    newMapping = { varName: shortName, value: world.observer.getGlobal(fullName) }
    #    Object.assign(acc, { [roleName]: (acc[roleName] ? []).concat(newMapping) })
    #, {})

    []

  # (Array[Widget]) => Array[WidgetUpdate]
  _getWidgetUpdates: (widgets) ->
    widgets.map(
      (w) =>
        if @_hnwWidgetGlobalCache[w.variable] isnt w.currentValue
          @_hnwWidgetGlobalCache[w.variable] = w.currentValue
          switch w.type
            when "chooser"
              console.log("Hey, nl chooser", w)
            when "inputBox"
              console.log("Hey, nl input", w)
            when "monitor"
              console.log("Hey, nl monitor", w)
            when "output"
              console.log("Hey, nl output", w)
            when "slider"
              console.log("Hey, nl slider", w)
            when "switch"
              console.log("Hey, nl switch", w)
            when "hnwChooser"
              { type: "chooser", varName: w.variable, value: w.currentValue }
            when "hnwInputBox"
              { type: "inputBox", varName: w.variable, value: w.currentValue }
            when "hnwMonitor"
              { id: w.display, type: "monitor", value: w.currentValue }
            when "hnwOutput"
              console.log("Hey, output", w)
            when "hnwSlider"
              { type: "slider", varName: w.variable, value: w.currentValue }
            when "hnwSwitch"
              { type: "switch", varName: w.variable, value: w.currentValue }
        else
          { type: "no-update" }
    ).filter((x) -> x?)

  # (String, String, (Number) => String) => Unit
  registerMonitorFunc: (roleName, src, func) ->
    @_monitorFuncs[roleName] = Object.assign({}, @_monitorFuncs[roleName] ? {}, { [src.toLowerCase()]: [func, {}] })
    return

  # (UUID) => Object[String]
  monitorsFor: (uuid) ->

    { roleName, who } = window.clients[uuid]

    out = {}

    if roleName?
      if who?
        for k, [func, lastValues] of @_monitorFuncs[roleName]
          newValue = func(who)
          if lastValues[who] isnt newValue
            lastValues[who] = newValue
            out[k] = newValue
      else
        for k, [func, lastValues] of @_monitorFuncs[roleName]
          newValue = func()
          if lastValues[roleName] isnt newValue
            lastValues[roleName] = newValue
            out[k] = newValue


    out

  # (String) => Unit
  updateWithoutRendering: (uuidToIgnore) ->
    @_performUpdate(true, false, uuidToIgnore)
    return

  # (Number) => Unit
  setTargetFrameRate: (@_hnwTargetFPS) ->
    return

  # () => Unit
  disableCongestionControl: ->
    @_hnwIsCongested = false
    return

  # () => Unit
  enableCongestionControl: ->
    @_hnwIsCongested = true
    return

  # (Boolean, Boolean, String) => Unit
  _performUpdate: (isFullUpdate, shouldRepaint, uuidToIgnore) ->

    deepClone = (x) ->
      if (not x?) or (typeof(x) in ["number", "string", "boolean"])
        x
      else if Array.isArray(x)
        x.map(deepClone)
      else
        out = {}
        for key, value of x
          out[key] = deepClone(value)
        out

    mergeObjects = (obj1, obj2) ->

      helper = (x, y) ->
        for key, value of y
          x[key] =
            if x[key]? and (typeof value) is "object" and not Array.isArray(value)
              helper(x[key], value)
            else
              value
        x

      clone1 = deepClone(obj1)
      clone2 = deepClone(obj2)

      helper(clone1, clone2, {})

    # [T] @ (Object[T], Object[T]) => Object[T]
    objectDiff = (x, y) ->

      helper = (obj1, obj2) ->

        { eq } = tortoise_require('brazier/equals')

        out = {}

        for key, value of obj1
          key2 = key.toLowerCase()
          if not obj2[key2]?
            out[key] = value
          else if not eq(obj2[key2])(value)
            result =
              if (typeof value) is "object" and not Array.isArray(value)
                helper(value, obj2[key2])
              else
                value
            if result?
              out[key] = result

        if Object.keys(out).length > 0
          out
        else
          undefined

      helper(x, y) ? {}

    viewUpdates =
      if isFullUpdate and Updater.hasUpdates()
        Updater.collectUpdates()
      else
        []

    drawingUpdates = viewUpdates.map((vu) -> vu.drawingEvents).reduce(((acc, x) -> (acc ? []).concat(x ? [])), [])
    viewUpdates.forEach((vu) -> delete vu.drawingEvents)

    mergedUpdate = viewUpdates.reduce(mergeObjects, {})
    if drawingUpdates.length > 0
      mergedUpdate.drawingEvents = drawingUpdates

    # NOTE: I need to test this to see its performance implications
    diffedUpdate = objectDiff(mergedUpdate, @widgetController.viewController.model)
    @widgetController.viewController.applyUpdate(diffedUpdate)

    joinerDrawings =
      if (diffedUpdate.drawingEvents ? []).length > 0
        { drawingEvents: @_handleImageCache(diffedUpdate.drawingEvents) }
      else
        {}

    joinerUpdate = Object.assign({}, diffedUpdate, joinerDrawings)

    if shouldRepaint
      @widgetController.viewController.repaint()

    if Object.keys(@_subscriberObj).length > 0

      if window.isHNWHost is true

        ticks       = joinerUpdate?.world?[0]?.ticks ? null
        plotUpdates = @widgetController.getPlotUpdates() # What the heck?  Why are these not scoped to the UUID? TODO ???

        broadUpdate = @_pruneUpdate({ plotUpdates, viewUpdate: joinerUpdate }, @_lastBCastTicks)
        if Object.keys(broadUpdate).length > 0
          for uuid, wind of @_subscriberObj
            if uuid isnt uuidToIgnore and wind isnt null # Send to child `iframe`s, and to parent for broadcast to remotes
              wind.postMessage({ update: broadUpdate, type: "nlw-state-update" }, "*")

        for uuid, wind of @_subscriberObj
          if uuid isnt uuidToIgnore

            monitorUpdates = @monitorsFor(uuid)
            update         = @_pruneUpdate({ monitorUpdates }, @_lastBCastTicks)
            perspUpdate    = @_genPerspUpdate(uuid)

            if Object.keys(perspUpdate).length > 0
              update.viewUpdate          = update.viewUpdate ? {}
              update.viewUpdate.observer = perspUpdate

            if Object.keys(update).length > 0
              if wind isnt null
                wind.postMessage({ update, type: "nlw-state-update" }, "*")
              else
                narrowcastHNWPayload(uuid, "nlw-state-update", { update })

        @_lastBCastTicks = ticks

      else if window.isHNWJoiner is true
        goodWTypes    = ["slider", "switch", "inputBox", "chooser"]
        widgetUpdates = @_getWidgetUpdates(@widgetController.widgets()).filter((wup) -> wup.type in goodWTypes)
        widgetUpdates.forEach((wup) -> sendHNWData("hnw-widget-message", wup)) # Scope this better to individual clients

    return

  # (PlotsUpdate) => PlotsUpdate
  _prunePlotsUpdate: (plotsUpdate) ->
    out = {}
    Object.entries(plotsUpdate).forEach(([plotName, updates]) -> if updates.length > 0 then out[plotName] = updates)
    out

  # (HNWUpdate, Number) => SparseHNWUpdate
  _pruneUpdate: ({ widgetUpdates = {}, monitorUpdates = {}, plotUpdates = {}, viewUpdate = {} }, lastTicks) ->

    retainIff = (cond, key, value) -> if cond then { [key]: value } else {}

    prunedPlots = @_prunePlotsUpdate(plotUpdates)

    widgetObj  = retainIff(            (widgetUpdates).length > 0, "widgetUpdates" , widgetUpdates)
    monitorObj = retainIff(Object.keys(monitorUpdates).length > 0, "monitorUpdates", monitorUpdates)
    plotObj    = retainIff(Object.keys(prunedPlots   ).length > 0, "plotUpdates"   , prunedPlots)
    viewObj    = retainIff(Object.keys(viewUpdate    ).length > 0, "viewUpdate"    , viewUpdate)

    Object.assign({}, widgetObj, monitorObj, plotObj, viewObj)

  # (String) => ViewUpdate.Observer
  _genPerspUpdate: (uuid) ->

    { perspVar, roleName, who } = window.clients[uuid]

    if perspVar?

      plural     = world.breedManager.getSingular(roleName).name
      projection = -> SelfManager.self().getVariable(perspVar)
      persp      = world.turtleManager.getTurtleOfBreed(plural, who).projectionBy(projection)

      lastPersp  = @_hnwLastPersp[uuid]
      isStale    = (lastPersp? and persp[0] is lastPersp[0] and persp[1] is lastPersp[1] and persp[2] is lastPersp[2])

      if Array.isArray(persp) and (persp[0] is "follow" or persp[0] is "watch") and (not isStale)

        @_hnwLastPersp[uuid]   = persp
        [type, target, radius] = persp

        [{
          followRadius: radius
          perspective:  if type is "follow" then 2 else 3
          targetAgent:  [agentToInt(target), target.id]
        }]

      else
        {}

    else
      {}

  # (Object[Object[Any]]) => Object[Object[Any]]
  _handleImageCache: (drawingUpdates) ->

    hashStr = (str) ->
      hash = 0
      for i in [0...str.length]
        char  = str.charCodeAt(i)
        hash  = ((hash << 5) - hash) + char
        hash |= 0 # toInt
      hash

    drawingUpdates.map(
      (du) =>
        if du.type is "import-drawing"
          hash = hashStr(du.imageBase64)
          @_hnwImageCache[hash] = du.imageBase64
          { type: "import-drawing-raincheck", hash }
        else
          du
    )

  # (String) => String
  cashRainCheckFor: (id) ->
    @_hnwImageCache[id]

  # (String) => Unit
  narrowcast: (uuid, type, update) ->
    wind = @_subscriberObj[uuid]
    if Object.keys(update).length > 0
      if wind isnt null
        wind.postMessage({ update, type }, "*")
      else
        narrowcastHNWPayload(uuid, type, { update })
    return

  # (String, Array[Widget]) => Unit
  _updateMetadata: (code, widgets) ->

    r = @widgetController.ractive

    if r.get('isHNW') and r.get('isEditing')

      compileParams =
        { code:         code
        , widgets:      widgets
        , turtleShapes: turtleShapes ? []
        , linkShapes:   linkShapes   ? []
        }

      @compiler.fromModel(compileParams)

      @widgetController.ractive.set('metadata.globalVars', @compiler.listGlobalVars())
      @widgetController.ractive.set('metadata.procedures', @compiler.listProcedures())

      baseMetadata = @widgetController.ractive.get('metadata')

      for frame in Array.from(document.getElementById('config-frames').children) when frame.dataset.roleName?
        roleName = frame.dataset.roleName
        itsVars  = @compiler.listVarsForBreed(roleName)
        metadata = Object.assign({}, baseMetadata, { myVars: itsVars })
        frame.contentWindow.postMessage({ metadata, type: "update-metadata" }, "*")

    return
