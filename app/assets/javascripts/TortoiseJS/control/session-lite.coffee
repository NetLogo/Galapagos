DEFAULT_UPDATE_DELAY = 1000 / 60
MAX_UPDATE_DELAY     = 1000
FAST_UPDATE_EXP      = 0.5
SLOW_UPDATE_EXP      = 4
MAX_UPDATE_TIME      = 100

DEFAULT_REDRAW_DELAY = 1000 / 30
MAX_REDRAW_DELAY     = 1000
REDRAW_EXP           = 2

class window.SessionLite
  constructor: (@widgetController) ->
    @_eventLoopTimeout = -1
    @_lastRedraw = 0
    @_lastUpdate = 0
    @widgetController.ractive.on('editor.recompile', (event) => @recompile())

  startLoop: ->
    @widgetController.updateWidgets()
    requestAnimationFrame(@eventLoop)

  updateDelay: ->
    speed       = @widgetController.speed()
    if speed > 0
      speedFactor = Math.pow(Math.abs(speed), FAST_UPDATE_EXP)
      DEFAULT_UPDATE_DELAY * (1 - speedFactor)
    else
      speedFactor = Math.pow(Math.abs(speed), SLOW_UPDATE_EXP)
      MAX_UPDATE_DELAY * speedFactor + DEFAULT_UPDATE_DELAY * (1 - speedFactor)

  redrawDelay: ->
    speed       = @widgetController.speed()
    if speed > 0
      speedFactor = Math.pow(Math.abs(@widgetController.speed()), REDRAW_EXP)
      MAX_REDRAW_DELAY * speedFactor + DEFAULT_REDRAW_DELAY * (1 - speedFactor)
    else
      DEFAULT_REDRAW_DELAY

  eventLoop: (timestamp) =>
    @_eventLoopTimeout = requestAnimationFrame(@eventLoop)
    updatesDeadline = Math.min(@_lastRedraw + @redrawDelay(), now() + MAX_UPDATE_TIME)
    maxNumUpdates   = (now() - @_lastUpdate) / @updateDelay()

    for i in [1..maxNumUpdates] by 1 # maxNumUpdates can be 0. Need to guarantee i is ascending.
      @_lastUpdate = now()
      @widgetController.runForevers()
      if now() >= updatesDeadline
        break

    # First conditional checks if we're on time with updates. If so, we may as
    # well redraw. This keeps animations smooth for fast models. BCH 11/4/2014
    if i > maxNumUpdates or now() - @_lastRedraw > @redrawDelay()
      @_lastRedraw = now()
      # TODO: Once Updater.anyUpdates() exist, switch to only redrawing when there are updates
      @widgetController.redraw()
    @widgetController.updateWidgets()

  teardown: ->
    @widgetController.teardown()
    cancelAnimationFrame(@_eventLoopTimeout)

  recompile: ->
# This is a temporary workaround for the fact that models can't be reloaded without clearing the world
    world.clearAll();
    @widgetController.redraw()
    compile('code', @widgetController.code(), [], [], @widgetController.widgets, (res) ->
      if res.model.success
        globalEval(res.model.result)
      else
        alert(res.model.result.map((err) -> err.message).join('\n')))

window.Tortoise = {
  fromNlogo:         (nlogo, container, callback) ->
    compile("nlogo", nlogo, [], [], [], makeCompileCallback(container, callback))
  fromURL:           (url,   container, callback) ->
    compile("url",   url,   [], [], [], makeCompileCallback(container, callback))

  fromCompiledModel: (container, widgets, code, info, compiledSource = "", readOnly = false) ->
    widgetController = bindWidgets(container, widgets, code, info, readOnly)
    window.modelConfig ?= {}
    modelConfig.plotOps = widgetController.plotOps
    globalEval(compiledSource)
    new SessionLite(widgetController)
}

window.AgentModel = tortoise_require('agentmodel')

makeCompileCallback = (container, callback) ->
  (res) ->
    if res.model.success
      callback(Tortoise.fromCompiledModel(container, res.widgets, res.code, res.info, res.model.result))
    else
      container.innerHTML = res.model.result.map((err) -> err.message).join('<br/>')

window.compile = (source, model, commands, reporters, widgets,
                  onFulfilled, onRejected = (s) -> throw s) ->
  compileParams = {
    model: model,
    widgets: JSON.stringify(widgets),
    commands: JSON.stringify(commands),
    reporters: JSON.stringify(reporters)
  }
  compileCallback = (res) ->
    onFulfilled(JSON.parse(res))
  ajax('/compile-'+source, compileParams, compileCallback)

window.ajax = (url, params, callback) ->
  paramPairs = for key, value of params
    encodeURIComponent(key) + '=' + encodeURIComponent(value)
  req = new XMLHttpRequest()
  req.open('POST', url)
  req.onreadystatechange = ->
    if req.readyState == req.DONE
      callback(req.responseText)
  req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
  req.send(paramPairs.join('&'))

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

# performance.now gives submillisecond timing, which improves the event loop
# for models with submillisecond go procedures. Unfortunately, iOS Safari
# doesn't support it. BCH 10/3/2014
now = performance?.now.bind(performance) ? Date.now.bind(Date)
