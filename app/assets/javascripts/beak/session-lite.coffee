import { createCommonArgs, createNamedArgs, listenerEvents } from "../notifications/listener-events.js"

import HNWSession from "./hnw/session.js"

import runBabyBehaviorSpace     from "./babybehaviorspace.js"
import mangleExportedPlots      from "./mangle-exported-plots.js"
import performUpdate            from "./perform-update.js"
import { toNetLogoMarkdown }    from "./tortoise-utils.js"
import initializeUI             from "./widgets/initialize-ui.js"
import { runWithErrorHandling } from "./widgets/set-up-widgets.js"
import { cloneWidget }          from "./widgets/widget-properties.js"
import { serializeResources }   from "./external-resources.js"

MAX_UPDATE_DELAY     = 1000
FAST_UPDATE_EXP      = 0.5
SLOW_UPDATE_EXP      = 4
MAX_UPDATE_TIME      = 100

DEFAULT_REDRAW_DELAY = 1000 / 30
MAX_REDRAW_DELAY     = 1000
REDRAW_EXP           = 2

NETLOGO_VERSION      = '2.12.3'

# performance.now gives submillisecond timing, which improves the event loop
# for models with submillisecond go procedures. Unfortunately, iOS Safari
# doesn't support it. BCH 10/3/2014
now = performance?.now.bind(performance) ? Date.now.bind(Date)

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

class SessionLite

  hnw:              undefined # HNWSession
  widgetController: undefined # WidgetController

  # (Tortoise, Element|String, BrowserCompiler, Array[Rewriter], Array[Listener], Array[Widget],
  #   String, String, Boolean, String, String, NlogoSource, String, Boolean)
  constructor: (@tortoise, container, @compiler, @rewriters, listeners, widgets,
    code, info, isReadOnly, @locale, workInProgressState, @nlogoSource, modelJS, lastCompileFailed) ->

    @hnw = new HNWSession( (() => @widgetController)
                         , ((ps) => @compiler.compilePlots(ps)))

    @_eventLoopTimeout = -1
    @_lastRedraw       = 0
    @_lastUpdate       = 0
    @drawEveryFrame    = false

    @widgetController = initializeUI(
      container
    , widgets
    , code
    , info
    , isReadOnly
    , @nlogoSource
    , workInProgressState
    , @compiler
    , (=> @_performUpdate())
    )

    # coffeelint: disable=max_line_length
    ractive = @widgetController.ractive
    ractive.on('*.recompile'     , (_, source)         => @recompile(source))
    ractive.on('*.recompile-sync', (_, source)         => @recompileSync(source, "", "", {}))
    ractive.on('*.recompile-for-plot', (_, source, oldName, newName, renamings) => @recompile(source, oldName, newName, renamings))
    ractive.on('export-nlogo'    , (_, event)          => @exportNlogoXML(event))
    ractive.on('export-html'     , (_, event)          => @exportHtml(event))
    ractive.on('open-new-file'   , (_)                 => @openNewFile())
    ractive.on('*.revert-wip'    , (_)                 => @revertWorkInProgress())
    ractive.on('*.undo-revert'   , (_)                 => @undoRevert())
    ractive.on('*.run'           , (_, source, code)   => @run(source, code))
    ractive.on('*.set-global'    , (_, varName, value) => @setGlobal(varName, value))

    listenerEvents.forEach( (event) ->
      listeners.forEach( (l) ->
        if l[event.name]?
          ractive.on("*.#{event.name}", (_, args...) ->
            commonArgs = createCommonArgs()
            eventArgs  = createNamedArgs(event.args, args)
            l[event.name](commonArgs, eventArgs)
            return
          )
        return
      )
    )

    ractive.on('*.recompile-procedures', (_, proceduresCode, procedureNames, successCallback) =>
      @recompileProcedures(proceduresCode, procedureNames, successCallback)
    )
    # coffeelint: enable=max_line_length

    ractive.set('lastCompileFailed', lastCompileFailed)

    # The global 'modelConfig' variable is used by the Tortoise runtime - David D. 7/2021
    window.modelConfig         = Object.assign(window.modelConfig ? {}, @widgetController.configs)
    window.modelConfig.version = NETLOGO_VERSION
    globalEval(modelJS)
    if workspace.i18nBundle.supports(@locale)
      workspace.i18nBundle.switch(@locale)
    else
      console.warn("Unsupported locale '#{@locale}', reverting to 'en_us'.")
      @locale = 'en_us'

  modelTitle: ->
    @widgetController.ractive.get('modelTitle')

  startLoop: ->
    if not @hnw.isJoiner() and ProcedurePrims.hasCommand('startup')
      runWithErrorHandling('startup', @widgetController.reportError, () -> ProcedurePrims.callCommand('startup'))
      @widgetController.ractive.fire('startup-procedure-run')
    @_performUpdate()
    @widgetController.updateWidgets()
    @_eventLoopTimeout = requestAnimationFrame(@eventLoop)
    @widgetController.ractive.set('isSessionLoopRunning', true)
    @widgetController.ractive.fire('session-loop-started')
    return

  # () => Unit
  initHNW: ->
    @hnw.init()

  calcNumUpdates: ->
    if @drawEveryFrame
      1
    else
      (now() - @_lastUpdate) / @updateDelay()

  updateDelay: ->

    if @hnw.isHost()
      @hnw.updateDelay()
    else

      speed = @widgetController.speed()
      delay = 1000 / @widgetController.getFPS()

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

    [mayLoop, mayTick] = @hnw.checkTickability(time)

    if mayLoop

      @hnw.updateLoopTime(time)

      if mayTick
        if not @widgetController.ractive.get('isEditing')

          @hnw.updateTickTime(time)

          for i in [1..maxNumUpdates] by 1 # maxNumUpdates can be 0. Need to guarantee i is ascending.
            @_lastUpdate = now()
            @widgetController.runForevers()
            @hnw.go()
            if now() >= updatesDeadline
              break

      if Updater.hasUpdates() or @hnw.shouldUpdate()
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
      # only concerns itself with View updates. --Jason B. (9/2/15)
      @widgetController.updateWidgets()

  teardown: ->
    @widgetController.teardown()
    cancelAnimationFrame(@_eventLoopTimeout)

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

  # ("user" | "system", String, String, Object[String]) => Unit
  recompileSync: (source, oldPlotName, newPlotName, plotRenames) ->
    if @widgetController.ractive.get('isEditing') and @hnw.isHNW()
      parent.postMessage({ type: "recompile" }, "*")
    else

      code          = @widgetController.code()
      oldWidgets    = @widgetController.widgets()
      rewritten     = @rewriteCode(code)
      extraCommands = @rewriterCommands()
      resources     = serializeResources()

      compileParams = {
        code:         rewritten
      , widgets:      oldWidgets.map(cloneWidget)
      , commands:     extraCommands
      , reporters:    []
      , turtleShapes: turtleShapes ? []
      , linkShapes:   linkShapes ? []
      , resources:    resources
      }

      @widgetController.ractive.fire('recompile-start', source, rewritten, code)

      try
        res = @compiler.fromModel(compileParams)
        if res.model.success

          state           = world.exportState()
          breeds          = Object.values(world.breedManager.breeds())
          breedShapePairs = breeds.map((b) -> [b.name, b.getShape()])
          @_performUpdate(true)
          # Redraw right before `Updater` gets clobbered --Jason B. (2/27/18)

          if oldPlotName isnt newPlotName
            pops = @widgetController.configs.plotOps
            pops[oldPlotName].dispose()
            delete pops[oldPlotName]

          @widgetController.ractive.set('isStale',           false)
          @widgetController.ractive.set('lastCompiledCode',  code)
          @widgetController.ractive.set('lastCompileFailed', false)
          @_performUpdate(true)
          @widgetController.freshenUpWidgets(oldWidgets, globalEval(res.widgets))
          viewWidget = @widgetController.widgets().find(({ type }) -> type is 'view')
          @widgetController.viewController.resetModel(viewWidget)

          globalEval(res.model.result)
          workspace.i18nBundle.switch(@locale)

          breedShapePairs.forEach(([name, shape]) -> world.breedManager.get(name).setShape(shape))
          plots = plotManager.getPlots()
          state.plotManager =
            mangleExportedPlots(state.plotManager, plots, plotRenames, oldPlotName, newPlotName)
          world.importState(state)

          res.commands.forEach((c) -> if c.success then (new Function(c.result))())
          @rewriters.forEach((rw) -> rw.compileComplete?())
          @widgetController.ractive.fire('recompile-complete', source, rewritten, code)

        else
          @widgetController.ractive.set('lastCompileFailed', true)
          errors = @rewriteErrors(code, rewritten, res.model.result)
          @widgetController.reportError('compiler', 'recompile', errors)

      catch ex
        @widgetController.reportError('compiler', 'recompile', [ex.toString()])

  # ("user" | "system", String, String, Object[String]) => Unit
  recompile: (source, oldPlotName = "", newPlotName = "", plotRenames = {}) ->
    @tortoise.startLoading( () =>
      @recompileSync(source, oldPlotName, newPlotName, plotRenames)
      @tortoise.finishLoading()
      return
    )
    return

  recompileProcedures: (proceduresCode, procedureNames, successCallback) ->
    try
      res = @compiler.compileProceduresIncremental(proceduresCode, procedureNames)
      if res.success
        globalEval(res.result)
        successCallback()
      else
        @widgetController.reportError('compiler', 'recompile-procedures', res.result)

    catch ex
      @widgetController.reportError('compiler', 'recompile-procedures', [ex.toString()])

    finally
      @tortoise.finishLoading()

    return

  getCode: ->
    @widgetController.code()

  getInfo: ->
    toNetLogoMarkdown(@widgetController.ractive.get('info'))

  getNlogo: ->
    info      = @getInfo()
    code      = @rewriteExport(@widgetController.code())
    widgets   = @widgetController.widgets().map(cloneWidget)
    resources = serializeResources()
    @compiler.exportNlogoXML({
      info:         info,
      code:         code,
      widgets:      widgets,
      turtleShapes: turtleShapes,
      linkShapes:   linkShapes,
      resources:    resources
    })

  exportNlogoXML: ->
    exportName = @promptFilename('.nlogox')
    if exportName?
      exportedNlogo = @getNlogo()
      if (exportedNlogo.success)
        exportBlob = new Blob([exportedNlogo.result], {type: 'text/plain:charset=utf-8'})
        saveAs(exportBlob, exportName)
        @widgetController.ractive.fire('nlogo-exported', exportName, exportedNlogo.result)

      else
        @widgetController.reportError('compiler', 'export-nlogo', exportedNlogo.result)

  promptFilename: (extension) =>
    suggestion = @modelTitle() + extension
    window.prompt('Filename:', suggestion)

  exportHtml: ->
    exportName = @promptFilename('.html')
    if exportName?
      exportHtmlEx = (htmlString) =>
        parser = new DOMParser()
        dom = parser.parseFromString(htmlString, 'text/html')

        await @widgetController.onBeforeExportHTMLDocument(dom)

        nlogo = @getNlogo()
        if nlogo.success
          nlogoScript = dom.querySelector('#nlogo-code')
          nlogoScript.textContent = nlogo.result
          nlogoScript.dataset.filename = exportName.replace(/\.html$/, '.nlogox')
          wrapper = document.createElement('div')
          wrapper.appendChild(dom.documentElement)
          exportBlob = new Blob([wrapper.innerHTML], {type: 'text/html:charset=utf-8'})
          saveAs(exportBlob, exportName)
          @widgetController.ractive.fire('html-exported', exportName, nlogo.result)

        else
          @widgetController.reportError('compiler', 'export-html', nlogo.result)

      await @widgetController.onBeforeExportHTMLFetch()
      if ['https:', 'http:'].includes(window.location.protocol)
        req = new XMLHttpRequest()
        req.open('GET', window.standaloneURL)
        req.onreadystatechange = =>
          if req.readyState is req.DONE
            if req.status is 200
              exportHtmlEx(req.responseText)
            else
              alert("Couldn't get standalone page")

        req.send("")

      else
        # assume we're a standalone local HTML `file://`
        quine = window.document.children.item(0).outerHTML
        exportHtmlEx(quine)

  # () => Unit
  openNewFile: ->

    # coffeelint: disable=max_line_length
    if window.confirm("Are you sure you want to open a new model?\n\nYour work in progress will be saved to your browser's cache to be reloaded the next time you load this model, but exporting your work is the best way to make sure you have a copy.")
    # coffeelint: enable=max_line_length

      if (parent isnt window)
        parent.postMessage({
          hash: 'NewModel',
          type: 'nlw-set-hash'
        }, "*")

      else
        window.postMessage({
          type: 'nlw-open-new'
        }, "*")

    return

  # () => Unit
  revertWorkInProgress: () ->
    window.postMessage({
      type: 'nlw-revert-wip'
    }, "*")

    return

  # () => Unit
  undoRevert: () ->
    window.postMessage({
      type: 'nlw-undo-revert'
    }, "*")

    return

  # (Object[Any], ([{ config: Object[Any], results: Object[Array[Any]] }]) => Unit) => Unit
  asyncRunBabyBehaviorSpace: (config, reaction) ->
    @tortoise.startLoading(=>
      reaction(@runBabyBehaviorSpace(config))
      @tortoise.finishLoading()
    )

  # (Object[Any]) => [{ config: Object[Any], results: Object[Array[Any]] }]
  runBabyBehaviorSpace: ({ experimentName, parameterSet, repetitionsPerCombo, metrics, setupCode, goCode
                         , stopConditionCode, iterationLimit }) ->

    { last, map, toObject, zip } = tortoise_require('brazier/array')
    { pipeline                 } = tortoise_require('brazier/function')

    rewritten  = @rewriteCode(@widgetController.code())
    oldWidgets = @widgetController.widgets().map(cloneWidget)
    result     = @compiler.fromModel({
      code:         rewritten
    , widgets:      oldWidgets
    , commands:     [setupCode, goCode]
    , reporters:    metrics.map((m) -> m.reporter).concat([stopConditionCode])
    , turtleShapes: []
    , linkShapes:   []
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

    runBabyBehaviorSpace(massagedConfig, setGlobal, miniDump)

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
    runWithErrorHandling(source, @widgetController.reportError, command, code)
    return

  # (String) => { success: true, value: Any } | { success: false, error: String }
  runReporter: (code) ->
    reporterResult = @compiler.compileReporter(code)

    { result, success } = reporterResult
    if not success
      return { success: false, error: "Reporter compile error: #{result}" }

    reporter = new Function("return ( #{result} );")
    return try
      reporterValue = reporter()
      { success: true, value: reporterValue }
    catch ex
      { success: false, error: "Runtime error: #{ex.toString()}" }

  # () => Unit
  updateWithoutRendering: ->
    @_performUpdate(true, false)
    return

  # (Boolean, Boolean) => Unit
  _performUpdate: (isFullUpdate = false, shouldRepaint = false) ->
    performUpdate(@widgetController, @hnw, isFullUpdate, shouldRepaint)
    return

export default SessionLite
