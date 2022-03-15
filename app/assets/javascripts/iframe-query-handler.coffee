import { cloneWidget } from "/beak/widgets/widget-properties.js"

{ createExportValue } = tortoise_require('engine/core/world/export')

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

# type Query = GlobalsQuery | ReporterQuery | WidgetsQuery | InfoQuery | CodeQuery | NlogoFileQuery

# type GlobalsQuery = {
#   type: 'globals'
#   variableFilters: Array[String] | null
# }

# type WidgetsQuery = {
#   type: 'widgets'
# }

# type InfoQuery = {
#   type: 'info'
# }

# type CodeQuery = {
#   type: 'code'
# }

# type NlogoFileQuery = {
#   type: 'nlogo-file'
# }

# type ReporterQuery = {
#   type: 'reporter'
#   code: String
# }

# type QueryResult = GlobalsResult | ReporterResult | WidgetsResult | InfoResult | CodeResult | NlogoFileResult

# type GlobalsResult = {
#   type: 'globals-result'
#   globals: Array[{ name: String, value: JSON }]
# }

# type WidgetsResult = {
#   type: 'widgets-result'
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
#   type: 'info-result'
#   nlogo: String
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

# (Query) => Any
handleQuery = (query) ->
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

    else
      throw new Error("Unknown query: #{query}")

# () => Unit
createQueryHandler = () ->
  window.addEventListener('message', (event) ->
    if event.data.type is 'nlw-query'
      results = event.data.queries.map(handleQuery)
      postMessage(event.source, event.data.queries, event.data.sourceInfo, results)
    return
  )
  return

export { createQueryHandler }
