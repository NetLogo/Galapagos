self.window = self
self.importScripts('/tortoise-compiler.js', '/netlogo-engine.js')

Exception = tortoise_require('util/exception')

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

widgetHandlers = {}

normalizedFileName = (path) ->
  pathComponents = path.split(/\/|\\/)
  decodeURI(pathComponents[pathComponents.length - 1])

commandCompile = (code, commands, reporters, widgets, onFulfilled, onErrors) ->
  compileParams = {
    code:         code,
    widgets:      widgets,
    commands:     commands,
    reporters:    reporters,
    turtleShapes: turtleShapes ? [],
    linkShapes:   linkShapes ? []
  }
  try
    onFulfilled((new BrowserCompiler()).fromModel(compileParams))
  catch ex
    onErrors([ex])
  finally
    postToMain('FINISH_LOADING')

serverNlogoCompile = (model, commands, reporters, widgets, onFulfilled) ->
  compileParams = {
    model:     model,
    commands:  JSON.stringify(commands),
    reporters: JSON.stringify(reporters)
  }
  compileCallback = (res) ->
    onFulfilled(JSON.parse(res))
  ajax('/compile-nlogo', compileParams, compileCallback)

serverCodeCompile = (code, commands, reporters, widgets, onFulfilled) ->
  compileParams = {
    code,
    widgets:      JSON.stringify(widgets),
    commands:     JSON.stringify(commands),
    reporters:    JSON.stringify(reporters),
    turtleShapes: JSON.stringify(turtleShapes ? []),
    linkShapes:   JSON.stringify(linkShapes ? [])
  }
  compileCallback = (res) ->
    onFulfilled(JSON.parse(res))
  ajax('/compile-code', compileParams, compileCallback)

ajax = (url, params, callback) ->
  paramPairs = for key, value of params
    encodeURIComponent(key) + '=' + encodeURIComponent(value)
  req = new XMLHttpRequest()
  req.open('POST', url)
  req.onreadystatechange = ->
    if req.readyState == req.DONE
      callback(req.responseText)
  req.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
  req.send(paramPairs.join('&'))

handlingErrors = (f) -> ->
  try f()
  catch ex
    if not (ex instanceof Exception.HaltInterrupt)
      message =
        if not (ex instanceof TypeError)
          ex.message
        else
          """A type error has occurred in the simulation engine.
             More information about these sorts of errors can be found
             <a href="https://netlogoweb.org/info#type-errors">here</a>.<br><br>
             Advanced users might find the generated error helpful, which is as follows:<br><br>
             <b>#{ex.message}</b><br><br>
          """
      # postRuntimeError takes an array
      postRuntimeError([message])
      throw new Exception.HaltInterrupt
    else
      throw ex

handleCompileResult = ({ commands, model: { result: modelResult, success: modelSuccess } }) =>
  if modelSuccess
    [{ result, success }] = commands
    if (success)
      try handlingErrors(new Function(result))()
      catch ex
        if not (ex instanceof Exception.HaltInterrupt)
          throw ex
    else
      postCompileError(result)
  else
    postCompileError(modelResult)

########################
# Event loop
########################

MAX_UPDATE_DELAY     = 1000
FAST_UPDATE_EXP      = 0.5
SLOW_UPDATE_EXP      = 4
MAX_UPDATE_TIME      = 100

DEFAULT_REDRAW_DELAY = 1000 / 30
MAX_REDRAW_DELAY     = 1000
REDRAW_EXP           = 2

rafId = -1
lastRedraw = 0
lastUpdate = 0
drawEveryFrame = false

eventLoop = (timestamp) ->
  # rafId = requestAnimationFrame(eventLoop)
  # debugger
  updatesDeadline = Math.min(lastRedraw + redrawDelay, now() + MAX_UPDATE_TIME)

  # updateDelay() = 100
  maxNumUpdates = if drawEveryFrame then 1 else (now() - lastUpdate) / 100

  for i in [1..maxNumUpdates] by 1  # maxNumUpdates can be 0. Need to guarantee i is ascending.
    lastUpdate = now()
    if now() >= updatesDeadline
      break

  if Updater.hasUpdates()
    redrawDelay = DEFAULT_REDRAW_DELAY
    if i > maxNumUpdates or
      now() - lastRedraw > DEFAULT_REDRAW_DELAY or
      drawEveryFrame
        lastRedraw = now()
        updates = Updater.collectUpdates()
        postViewStateUpdate(updates)

self.setInterval(eventLoop, 5000)

########################
# Posting messages
########################

postViewStateUpdate = (updates) ->
  postToMain('VIEW_STATE_UPDATE', { updates })

postRuntimeError = (messages) ->
  postToMain('RUNTIME_ERROR', { messages })

postCompileError = (result) ->
  # Errors can't be cloned, so we can't post them directly.
  postToMain('COMPILATION_ERROR',
    { messages: result.map((err) -> { message: err.message, stack: err.stack }) })

postNlogoCompileResult = (data) ->
  postToMain('INITIAL_COMPILE_RESULT', data)

# string, JSON ->
postToMain = (type, data) -> self.postMessage({ type, data })

########################
# Receiving messages
########################

# have an updater and the window polls the worker

self.addEventListener('message', ({ data: { type, data } }) ->
  action = {
    'RUN_BUTTON': () ->
      { id } = data
      widgetHandlers[id]()

    'COMMAND_COMPILE': () ->
      [ codeTab, commandCenter, reporters, widgets ] = data.compileArgs
      commandCompile(
        codeTab,
        commandCenter,
        reporters,
        JSON.parse(widgets),  # temp -- stringified to avoid runtime errors
        handleCompileResult,
        postCompileError)

    'INITIAL_COMPILE': () ->
      { model, commands, modelPath, name } = data
      compileResult = (new BrowserCompiler()).fromNlogo(model, commands)

      # Store widget handlers in a map
      globalEval(compileResult.widgets)
        .forEach((w, i) ->
          if w.type is 'button' or w.type is 'monitor'
            widgetHandlers[i] =
              if w.compilation.success
                handlingErrors(new Function(w.compiledSource))
              else
                # Make error handling better by not having fake semantic
                # names that actually correspond to differences in
                # data forms.
                () -> postRuntimeError(['Button failed to compile with:'].concat(w.compilation.messages)))

      modelName = name ? normalizedFileName(modelPath)
      self.modelConfig = {}
      self.modelConfig.print = {
        write: (message) -> postToMain('PRINT', { message })
      }
      selfResult = compileResult.model.result # .replace(/\bwindow\b/g, 'self')
      globalEval(selfResult)

      postNlogoCompileResult({
        compileResult,
        modelName,
      })

    'POISON_PILL': () -> self.close()
  }[type]

  if action
    action()
  else
    postToMain('ERROR', { message: "Received undefined message type #{type}" })
)

now = performance?.now.bind(performance) ? Date.now.bind(Date)
