self.importScripts('/tortoise-compiler.js', '/netlogo-engine.js')

Exception = tortoise_require('util/exception')

# See http://perfectionkills.com/global-eval-what-are-the-options/ for what
# this is doing. This is a holdover till we get the model attaching to an
# object instead of global namespace. - BCH 11/3/2014
globalEval = eval

normalizedFileName = (path) ->
  pathComponents = path.split(/\/|\\/)
  decodeURI(pathComponents[pathComponents.length - 1])

# codeCompile(data.compileArgs..., handleCompileResult, postCompileError)
codeCompile = (code, commands, reporters, widgets, onFulfilled, onErrors) ->
  compileParams = {
    code:         code,
    widgets:      widgets,
    commands:     commands,
    reporters:    reporters,
    turtleShapes: turtleShapes ? [],
    linkShapes:   linkShapes ? []
  }
  try
    onFulfilled((new BrowserCompiler()).fromModel(compileParams))  # find this
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
      postRuntimeError(message)
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
# Posting messages
########################

postRuntimeError = (messages) ->
  postToMain('RUNTIME_ERROR', { messages: [ messages ] })

postCompileError = (result) ->
  # Errors can't be cloned, so we can't post them directly.
  postToMain('COMPILATION_ERROR',
    { messages: result.map((err) -> { message: err.message, stack: err.stack }) })

postNlogoCompileResult = (data) ->
  postToMain('NLOGO_COMPILE_RESULT', data)

# string, JSON ->
postToMain = (type, data) -> self.postMessage({ type, data })

########################
# Receiving messages
########################

# have an updater and the window polls the worker

self.addEventListener('message', ({ data: { type, data } }) ->
  action = {
    'COMPILE_CODE': () ->
      codeCompile(data.compileArgs..., handleCompileResult, postCompileError)
    'NLOGO_COMPILE': () ->
      { model, commands, modelPath, name } = data
      compileResult = (new BrowserCompiler()).fromNlogo(model, commands)
      modelName = name ? normalizedFileName(modelPath)

      self.modelConfig = {}
      self.modelConfig.print = {
        write: (message) -> postToMain('PRINT', { message })
      }
      selfResult = compileResult.model.result.replace(/\bwindow\b/g, 'self')
      globalEval(selfResult)

      postNlogoCompileResult({
        compileResult,
        modelName,
      })
  }[type]

  if action
    action()
  else
    postToMain('ERROR', { message: "Received undefined message type #{type}" })
)
