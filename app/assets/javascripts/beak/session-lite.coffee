MAX_UPDATE_DELAY     = 1000
FAST_UPDATE_EXP      = 0.5
SLOW_UPDATE_EXP      = 4
MAX_UPDATE_TIME      = 100

DEFAULT_REDRAW_DELAY = 1000 / 30
MAX_REDRAW_DELAY     = 1000
REDRAW_EXP           = 2

NETLOGO_VERSION      = '2.8.4'

# performance.now gives submillisecond timing, which improves the event loop
# for models with submillisecond go procedures. Unfortunately, iOS Safari
# doesn't support it. BCH 10/3/2014
now = performance?.now.bind(performance) ? Date.now.bind(Date)

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

window.AgentModel = tortoise_require('agentmodel')

class window.SessionLite

  widgetController: undefined # WidgetController

  # (Element|String, BrowserCompiler, Array[Rewriter], Array[Widget],
  #   String, String, Boolean, String, String, Boolean)
  constructor: (container, @compiler, @rewriters, widgets,
    code, info, readOnly, filename, modelJS, lastCompileFailed) ->

    @_eventLoopTimeout = -1
    @_lastRedraw       = 0
    @_lastUpdate       = 0
    @drawEveryFrame    = false

    @widgetController = initializeUI(container, widgets, code, info, readOnly, filename, @compiler)
    @widgetController.ractive.on('*.recompile'     , (_, callback)       => @recompile(callback))
    @widgetController.ractive.on('*.recompile-lite', (_, callback)       => @recompileLite(callback))
    @widgetController.ractive.on('export-nlogo'    , (_, event)          => @exportNlogo(event))
    @widgetController.ractive.on('export-html'     , (_, event)          => @exportHtml(event))
    @widgetController.ractive.on('open-new-file'   , (_, event)          => @openNewFile())
    @widgetController.ractive.on('*.run'           , (_, source, code)   => @run(source, code))
    @widgetController.ractive.on('*.set-global'    , (_, varName, value) => @setGlobal(varName, value))
    @widgetController.ractive.set('lastCompileFailed', lastCompileFailed)

    window.modelConfig         = Object.assign(window.modelConfig ? {}, @widgetController.configs)
    window.modelConfig.version = NETLOGO_VERSION
    globalEval(modelJS)

  modelTitle: ->
    @widgetController.ractive.get('modelTitle')

  startLoop: ->
    if ProcedurePrims.hasCommand('startup')
      window.runWithErrorHandling('startup', @widgetController.reportError, () -> ProcedurePrims.callCommand('startup'))
    @widgetController.redraw()
    @widgetController.updateWidgets()
    requestAnimationFrame(@eventLoop)

  updateDelay: ->
    viewWidget = @widgetController.widgets().filter(({ type }) -> type is 'view')[0]
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
    @_eventLoopTimeout = requestAnimationFrame(@eventLoop)
    updatesDeadline = Math.min(@_lastRedraw + @redrawDelay(), now() + MAX_UPDATE_TIME)
    maxNumUpdates   = if @drawEveryFrame then 1 else (now() - @_lastUpdate) / @updateDelay()

    if not @widgetController.ractive.get('isEditing')
      for i in [1..maxNumUpdates] by 1 # maxNumUpdates can be 0. Need to guarantee i is ascending.
        @_lastUpdate = now()
        @widgetController.runForevers()
        if now() >= updatesDeadline
          break

    if Updater.hasUpdates()
      # First conditional checks if we're on time with updates. If so, we may as
      # well redraw. This keeps animations smooth for fast models. BCH 11/4/2014
      if i > maxNumUpdates or now() - @_lastRedraw > @redrawDelay() or @drawEveryFrame
        @_lastRedraw = now()
        @widgetController.redraw()

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

  # (String) => String
  rewriteCode: (code) ->
    rewriter = (newCode, rw) -> if rw.injectCode? then rw.injectCode(newCode) else newCode
    @rewriters.reduce(rewriter, code)

  rewriteExport: (code) ->
    rewriter = (newCode, rw) -> if rw.exportCode? then rw.exportCode(newCode) else newCode
    @rewriters.reduce(rewriter, code)

  # () => Array[String]
  rewriterCommands: () ->
    extrasReducer = (extras, rw) -> if rw.getExtraCommands? then extras.concat(rw.getExtraCommands()) else extras
    @rewriters.reduce(extrasReducer, [])

  # (String, String, Array[String])
  rewriteErrors: (original, rewritten, errors) ->
    errors = errors.map( (r) =>
      r.lineNumber = rewritten.slice(0, r.start).split("\n").length
      r
    )

    rewriter = (newErrors, rw) -> if rw.updateErrors?
      rw.updateErrors(original, rewritten, newErrors)
    else
      newErrors

    @rewriters.reduce(rewriter, errors)

  # (() => Unit) => Unit
  recompile: (successCallback = (->)) ->

    code          = @widgetController.code()
    oldWidgets    = @widgetController.widgets()
    rewritten     = @rewriteCode(code)
    extraCommands = @rewriterCommands()

    compileParams = {
      code:         rewritten,
      widgets:      oldWidgets,
      commands:     extraCommands,
      reporters:    [],
      turtleShapes: turtleShapes ? [],
      linkShapes:   linkShapes ? []
    }

    Tortoise.startLoading(=>

      try
        res = @compiler.fromModel(compileParams)
        if res.model.success

          state = world.exportState()
          @widgetController.redraw() # Redraw right before `Updater` gets clobbered --JAB (2/27/18)
          globalEval(res.model.result)
          world.importState(state)

          @widgetController.ractive.set('isStale',           false)
          @widgetController.ractive.set('lastCompiledCode',  code)
          @widgetController.ractive.set('lastCompileFailed', false)
          @widgetController.redraw()
          @widgetController.freshenUpWidgets(oldWidgets, globalEval(res.widgets))

          successCallback()
          res.commands.forEach((c) -> if c.success then (new Function(c.result))())
          @rewriters.forEach((rw) -> rw.compileComplete?())

        else
          @widgetController.ractive.set('lastCompileFailed', true)
          errors = @rewriteErrors(code, rewritten, res.model.result)
          @widgetController.reportError('compiler', 'recompile', errors)

      catch ex
        @widgetController.reportError('compiler', 'recompile', [ex.toString()])

      finally
        Tortoise.finishLoading()

      return
    )

    return

  getNlogo: ->
    @compiler.exportNlogo({
      info:         Tortoise.toNetLogoMarkdown(@widgetController.ractive.get('info')),
      code:         @rewriteExport(@widgetController.code()),
      widgets:      @widgetController.widgets(),
      turtleShapes: turtleShapes,
      linkShapes:   linkShapes
    })

  exportNlogo: ->
    exportName = @promptFilename('.nlogo')
    if exportName?
      exportedNLogo = @getNlogo()
      if (exportedNLogo.success)
        exportBlob = new Blob([exportedNLogo.result], {type: 'text/plain:charset=utf-8'})
        saveAs(exportBlob, exportName)
      else
        @widgetController.reportError('compiler', 'export-nlogo', exportedNLogo.result)

  promptFilename: (extension) =>
    suggestion = @modelTitle() + extension
    window.prompt('Filename:', suggestion)

  exportHtml: ->
    exportName = @promptFilename('.html')
    if exportName?
      window.req = new XMLHttpRequest()
      req.open('GET', standaloneURL)
      req.onreadystatechange = =>
        if req.readyState is req.DONE
          if req.status is 200
            nlogo = @getNlogo()
            if nlogo.success
              parser = new DOMParser()
              dom = parser.parseFromString(req.responseText, 'text/html')
              nlogoScript = dom.querySelector('#nlogo-code')
              nlogoScript.textContent = nlogo.result
              nlogoScript.dataset.filename = exportName.replace(/\.html$/, '.nlogo')
              wrapper = document.createElement('div')
              wrapper.appendChild(dom.documentElement)
              exportBlob = new Blob([wrapper.innerHTML], {type: 'text/html:charset=utf-8'})
              saveAs(exportBlob, exportName)
            else
              @widgetController.reportError('compiler', 'export-html', nlogo.result)
          else
            alert("Couldn't get standalone page")
      req.send("")

  # () => Unit
  openNewFile: ->

    if confirm('Are you sure you want to open a new model?  You will lose any changes that you have not exported.')

      parent.postMessage({
        hash: 'NewModel',
        type: 'nlw-set-hash'
      }, "*")

      window.postMessage({
        type: 'nlw-open-new'
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

    rewritten = @rewriteCode(@widgetController.code())
    result    = @compiler.fromModel({ code: rewritten, widgets: @widgetController.widgets()
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

  # (String, Any) => Unit
  setGlobal: (varName, value) ->
    world.observer.setGlobal(varName, value)
    return

  # (String, String) => Unit
  run: (source, code) ->

    commandResult = @compiler.compileCommand(code)

    { result, success } = commandResult
    if not success
      @widgetController.reportError('compiler', source, result)
      return

    command = new Function(result)
    window.runWithErrorHandling(source, @widgetController.reportError, command)
    return

  # (String) => { success: true, value: Any } | { success: false, error: String }
  runReporter: (code) ->
    result = @compiler.compileReporter(code)

    { result, success } = reporterResult
    if not success
      return { success: false, error: "Reporter error: #{result}" }

    reporter = new Function("return ( #{result} );")
    return try
      reporterValue = reporter()
      { success: true, value: reporterValue }
    catch ex
      { success: false, error: "Runtime error: #{ex.toString()}" }
