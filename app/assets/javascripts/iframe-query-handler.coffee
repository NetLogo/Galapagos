import { cloneWidget } from "/beak/widgets/widget-properties.js"

{ fold } = tortoise_require('brazier/maybe')
{ createExportValue } = tortoise_require('engine/core/world/export')
{ Perspective } = tortoise_require('engine/core/observer')

postMessage = (target, queries, sourceInfo, results) ->
  target.postMessage({ type:  'nlw-query-response', queries, sourceInfo, results }, '*')
  return

filterNames = (names, maybeFilter) ->
  filteredNames = if maybeFilter?
    names.filter( (name) -> maybeFilter.includes(name) )
  else
    names

# type QueryRequest = {
#   type: 'nlw-query'
#   queries: Array[Query]
#   sourceInfo: String | null
# }

# type QueryResponse = {
#   type: 'nlw-query-response'
#   results: Array[QueryResult]
#   sourceInfo: String | null
# }

# type Query = GlobalsQuery | ReporterQuery | SimpleQuery

# type GlobalsQuery = {
#   type: 'globals'
#   variableFilters: Array[String] | null
# }

# type ReporterQuery = {
#   type: 'reporter'
#   code: String
# }

# type SimpleQuery = {
#   type: 'widgets' | 'info' | 'code' | 'nlogo-file' | 'metadata'
# }

# type QueryResult = GlobalsResult | ReporterResult | WidgetsResult | InfoResult | CodeResult | NlogoFileResult

# type GlobalsResult = {
#   type:    'globals-result'
#   globals: Array[{ name: String, value: JSON }]
# }

# type WidgetsResult = {
#   type:    'widgets-result'
#   widgets: Array[Widget]
# }

# type InfoResult = {
#   type: 'info-result'
#   info: String
# }

# type CodeResult = {
#   type: 'code-result'
#   code: String
# }

# type NlogoFileResult = {
#   type:  'info-result'
#   nlogo: String
# }

# type NlogoSource = DiskSource | UrlSource | NewSource | EmbeddedSource

# type DiskSource = { type: 'disk', fileName: String }
# type UrlSource = { type: 'url', fileName: String, url: String }
# type NewSource = { type: 'new' }
# type ScriptSource = { type: 'script-element' }

# type MetadataResult = {
#   type:         'metadata-result'
#   title:        String
#   source:       NlogoSource
#   speed:        Number
#   currentPlot:  String | null
#   focusedAgent: AgentRef | null
# }

# type ReporterResult = SuccessResult | FailureResult

# type SuccessResult = {
#   type: 'reporter-result'
#   success: true
#   value: JSON
# }

# type FailureResult = {
#   type: 'reporter-result'
#   success: false
#   result:  ErrorInfo
# }

getCurrentPlot = (plotManager) ->
  fold( () -> null )( (p) -> p.name )(plotManager.getCurrentPlotMaybe())

getPerspective = (observer) ->
  targetAgent     = observer._targetAgent
  perspectiveType = observer.getPerspective()
  {
    type: if perspectiveType? then Perspective.perspectiveToString(perspectiveType) else 'unset'
    targetAgent: if targetAgent? then targetAgent.toString() else 'nobody'
  }

getSource = (source) ->
  switch source.type
    when 'disk'
      { type: session.nlogoSource.type, fileName: session.nlogoSource.fileName }

    when 'url'
      { type: session.nlogoSource.type, fileName: session.nlogoSource.fileName, url: session.nlogoSource.url }

    when 'new'
      { type: session.nlogoSource.type, fileName: session.nlogoSource.fileName }

    when 'script-element'
      { type: session.nlogoSource.type }

    else
      throw new Error("Unknown file source: #{source}")

# (SessionLite, Query) => Any
handleQuery = (session, query) ->
  switch query.type
    when 'globals'
      observer    = workspace.world.observer
      exportValue = createExportValue(workspace.world)
      globalNames = filterNames(observer.varNames(), query.variableFilters)
      globals = globalNames.map( (global) -> {
        name:  global
      , value: exportValue(observer.getGlobal(global))
      })
      { type: 'globals-result', globals }

    when 'reporter'
      result = session.runReporter(query.code)
      result.type = 'reporter-result'

      if result.success
        exportValue  = createExportValue(workspace.world)
        result.value = exportValue(result.value)

      result

    when 'widgets'
      widgets = session.widgetController.widgets().map(cloneWidget)
      { type: 'widgets-result', widgets }

    when 'info'
      info = session.getInfo()
      { type: 'info-result', info }

    when 'code'
      code = session.getCode()
      { type: 'code-result', code }

    when 'nlogo-file'
      nlogo = session.getNlogo()
      { type: 'nlogo-file-result', nlogo }

    when 'metadata'
      {
        type: 'metadata-result'
      , title: session.modelTitle()
      , source: getSource(session.nlogoSource)
      , speed: session.widgetController.speed()
      , ticks: session.widgetController.ractive.get('ticks')
      , currentPlot: getCurrentPlot(workspace.plotManager)
      , perspective: getPerspective(workspace.world.observer)
      }

    else
      throw new Error("Unknown query: #{query}")

# (() => SessionLite) => Unit
attachQueryHandler = (getSession) ->
  handler = (query) -> handleQuery(getSession(), query)
  window.addEventListener('message', (event) ->
    if event.data.type is 'nlw-query'
      results = event.data.queries.map(handler)
      postMessage(event.source, event.data.queries, event.data.sourceInfo, results)
    return
  )
  return

export { attachQueryHandler }
