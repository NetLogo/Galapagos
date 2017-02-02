# Needs to go with newSession
globalEval = eval

# Poached from tortoise.coffee - temporary home :')
newSession = (container, modelResult, readOnly = false, filename = "export", onError = undefined) ->
  widgets = globalEval(modelResult.widgets)
  widgetController = bindWidgets(container, widgets, modelResult.code,
    Tortoise.toNetLogoWebMarkdown(modelResult.info), readOnly, filename)
  window.modelConfig ?= {}
  modelConfig.plotOps   = widgetController.plotOps
  modelConfig.exporting = widgetController.exporting
  modelConfig.mouse     = widgetController.mouse
  modelConfig.print     = { write: widgetController.write }
  modelConfig.output    = widgetController.output
  modelConfig.dialog    = widgetController.dialog
  modelConfig.world     = widgetController.worldConfig
  globalEval(modelResult.model.result)  # needs to be on worker
  new SessionLite(widgetController, onError)

class window.WorkerManager
  _worker: undefined

  constructor: (@_displayError) ->
    @_worker = new Worker('/assets/javascripts/TortoiseJS/control/worker.js')
    @_worker.addEventListener('message', @handleWorkerMessage)

  getWorker: -> @_worker

  handleWorkerMessage: ({ data: { type, data } }) =>
    action = {
      'COMPILATION_ERROR': ({ messages }) =>
        message = messages.map((m) -> m.message).join('\n')
        @_displayError(message)
      'ERROR': (data) ->
        console.error("worker: #{data.message}")
      'RUNTIME_ERROR': (data) ->
        window.showErrors(data.messages)
      'FINISH_LOADING': (data) ->
        window.Tortoise.finishLoading()
      'INITIAL_COMPILE_RESULT': (data) =>
        { compileResult, name } = data
        session = newSession(modelContainer, compileResult, false, name, @_displayError)

        # Finish loading
        document.querySelector("#loading-overlay").style.display = "none"
        openSession(session)
      'PRINT': (data) ->
        session.widgetController.write(data.message)
    }[type]

    if action?
      action(data)
    else
      console.error("main: received message from worker, but type #{type} was not recognized")
