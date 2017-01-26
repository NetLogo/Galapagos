worker = new Worker('/assets/javascripts/TortoiseJS/control/worker.js')

globalEval = eval

# Poached from tortoise.coffee
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

alertCompileError = (result) ->
  result.map((err) -> err.message).join('\n')
  alert(JSON.stringify(result))  # very jank

handleWorkerMessage = ({ data: { type, data } }) ->
  action = {
    'COMPILATION_ERROR': (data) -> alertCompileError(data)
    'ERROR': (data) -> console.error("worker: #{data.message}")
    'RUNTIME_ERROR': (data) -> window.showErrors(data.messages)
    'FINISH_LOADING': (data) -> window.Tortoise.finishLoading()
    'NLOGO_COMPILE_RESULT': (data) ->
      { compileResult, name } = data
      session = newSession(modelContainer, compileResult, false, name, alertCompileError)

      # Finish loading
      document.querySelector("#loading-overlay").style.display = "none"
      openSession(session)
    'PRINT': (data) -> session.widgetController.write(data.message)
  }[type]

  if action?
    action(data)
  else
    console.error("main: received message from worker, but type #{type} was not recognized")

worker.addEventListener('message', handleWorkerMessage)
window.worker = worker

