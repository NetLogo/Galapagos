import { createModelOracle } from "./model-oracle.js"

postMessage = (target, queries, sourceInfo, results) ->
  target.postMessage({ type:  'nlw-query-response', queries, sourceInfo, results }, '*')
  return

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
#   type: 'widgets' | 'info' | 'code' | 'nlogo-file' | 'metadata' | 'view'
# }

# type QueryResult = GlobalsResult | ReporterResult | WidgetsResult | InfoResult | CodeResult | NlogoFileResult |
#   MetadataResult | ViewResult

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

# type ViewResult = {
#   type:   'view-result'
#   base64: String
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

# (ModelOracle, Query) => QueryResult
handleQuery = (oracle, query) ->
  switch query.type
    when 'globals'
      globals = oracle.getGlobals(query.variableFilters)
      { type: 'globals-result', globals }

    when 'reporter'
      result = oracle.runReporter(query.code)
      result.type = 'reporter-result'
      result

    when 'widgets'
      widgets = oracle.getWidgets()
      { type: 'widgets-result', widgets }

    when 'info'
      info = oracle.getInfo()
      { type: 'info-result', info }

    when 'code'
      code = oracle.getCode()
      { type: 'code-result', code }

    when 'nlogo-file'
      nlogo = oracle.getNlogo()
      { type: 'nlogo-file-result', nlogo }

    when 'metadata'
      {
        type:        'metadata-result'
      , title:       oracle.getModelTitle()
      , source:      oracle.getSource()
      , speed:       oracle.getSpeed()
      , ticks:       oracle.getTicks()
      , currentPlot: oracle.getCurrentPlot()
      , perspective: oracle.getCurrentPerspective()
      }

    when 'view'
      base64 = oracle.getView()
      { type: 'view-result', base64 }

    else
      throw new Error("Unknown query: #{query}")

# (() => SessionLite) => Unit
attachQueryHandler = (getSession) ->
  oracle = null
  handler = (query) ->
    currentSession = getSession()
    if (not oracle?) or oracle.session isnt currentSession
      oracle = createModelOracle(currentSession, globalThis.workspace)
    handleQuery(oracle, query)

  window.addEventListener('message', (event) ->
    if (event.data? and event.data.type is 'nlw-query')
      results = event.data.queries.map(handler)
      postMessage(event.source, event.data.queries, event.data.sourceInfo, results)
    return
  )

  return

export { attachQueryHandler }
