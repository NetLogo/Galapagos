codeModalMonitor = null # MessagePort
ractive = null # Ractive
compiler = new BrowserCompiler()
codeTab = ""
widgets = []
hnwPortToIDMan = new Map()

loadCodeModal = ->

  # (NEW): Handle messages to code modal window (iframe)
  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-code-modal"
        codeModalMonitor = e.ports[0]
        codeModalMonitor.onmessage = onCodeModalMessage
        result = compiler.fromNlogo(e.data.nlogo)

        codeTab = result.code
        widgets = JSON.parse(result.widgets)
        hnwPortToIDMan.set(codeModalMonitor, new window.IDManager())

        return

    console.warn("Unknown code modal postMessage:", e.data)
  )

  # (NEW): Code modal setup
  template = """
    <label class="netlogo-tab netlogo-active">
      <input id="code-tab-toggle" type="checkbox" checked="true" />
      <span class="netlogo-tab-text">NetLogo Code</span>
    </label>
    <codePane code='' lastCompiledCode='{{lastCompiledCode}}' lastCompileFailed='false' isReadOnly='false' />
  """

  ractive = new Ractive({
    el:       document.getElementById("code-modal-container")
    template: template,
    components: {
      codePane: RactiveModelCodeComponent
    },
    data: -> {
      lastCompiledCode: ""
    }
  })

  ractive.on('*.recompile'     , (_, callback) => postToCodeModalMonitor({ type: "nlw-recompile", callback }))
  ractive.on('*.recompile-lite', (_, callback) => postToCodeModalMonitor({ type: "nlw-recompile-lite", callback }))

# (MessagePort) => Number
nextMonIDFor = (port) ->
  hnwPortToIDMan.get(port).next("")

# (MessagePort, Object[Any], Array[MessagePort]?) => Unit
postToCodeModalMonitor = (message, transfers = []) ->

  idObj    = { id: nextMonIDFor(codeModalMonitor) }
  finalMsg = Object.assign({}, message, idObj, { source: "nlw-host" })

  codeModalMonitor.postMessage(finalMsg, transfers)

# TODO
# (() => Unit) => Unit
# recompile = (successCallback = (->)) ->

#   if ractive.get('isEditing') and ractive.get('isHNW')
#     parent.postMessage({ type: "recompile" }, "*")
#   else

#     code       = codeTab
#     oldWidgets = widgets

#     onCompile =
#       (res) =>

#         if res.model.success

#           state = world.exportState()
#           breedShapePairs = world.breedManager.breeds().map((b) -> [b.name, b.getShape()])
#           world.clearAll()

#           widgets = Object.values(ractive.get('widgetObj'))

#           for { display, id, type } in widgets when type in ["plot", "hnwPlot"]
#             pops[display]?.dispose()
#             hops          = new HighchartsOps(ractive.find("#netlogo-#{type}-#{id}"))
#             pops[display] = hops
#             normies       = ractive.findAllComponents("plotWidget")
#             hnws          = ractive.findAllComponents("hnwPlotWidget")
#             component     = [].concat(normies, hnws).find((plot) -> plot.get("widget").display is display)
#             component.set('resizeCallback', hops.resizeElem.bind(hops))
#             hops._chart.chartBackground.css({ color: '#efefef' })

#           globalEval(res.model.result)
#           breedShapePairs.forEach(([name, shape]) -> world.breedManager.get(name).setShape(shape))

#           ractive.set('isStale',           false)
#           ractive.set('lastCompiledCode',  code)
#           ractive.set('lastCompileFailed', false)
#           widgets = globalEval(res.widgets)

#           successCallback()

#         else
#           ractive.set('lastCompileFailed', true)
#           res.model.result.forEach( (r) => r.lineNumber = code.slice(0, r.start).split("\n").length )
#           alertCompileError(res.model.result)

#     codeCompile(code, [], [], oldWidgets, onCompile, alertCompileError)

# # TODO
# alertCompileError = (result, errorLog = @alertErrors) ->
#   errorLog(result.map((err) -> if err.lineNumber? then "(Line #{err.lineNumber}) #{err.message}" else err.message))

# # TODO
# # (() => Unit) => Unit
# recompileLite: (successCallback = (->)) ->
#   lastCompileFailed   = ractive.get('lastCompileFailed')
#   someWidgetIsFailing = widgets().some((w) -> w.compilation?.success is false)
#   if lastCompileFailed or someWidgetIsFailing
#     recompile(successCallback)
#   return

# TODO
onCodeModalMessage = (e) ->

  switch (e.data.type)
    when "hnw-model-code"
      ractive.findComponent("codePane").setCode(e.data.code)
      ractive.set("lastCompiledCode", e.data.code)

loadCodeModal()
