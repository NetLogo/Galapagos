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

# type Query = GlobalsQuery | ReporterQuery

# type GlobalsQuery = {
#   type: 'globals'
#   variableFilters: Array[String] | null
# }

# type ReporterQuery = {
#   type: 'reporter'
#   code: String
# }

# type QueryResult = GlobalsResult | ReporterResult

# type GlobalsResult = {
#   type: 'globals-result'
#   name: String
#   value: JSON
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
      globalNames.map( (global) -> {
        type:  'globals-result'
      , name:  global
      , value: exportValue(observer.getGlobal(global))
      })

    when 'reporter'
      result = session.runReporter(query.code)
      if result.success
        exportValue = createExportValue(workspace.world)
        {
          type:    'reporter-result'
        , success: true
        , value:   exportValue(result.value)
        }
      else
        result.type = 'reporter-result'
        result

    else
      throw new Error("Unknown query: #{query}")

# () => Unit
createQueryHandler = () ->
  window.addEventListener("message", (event) ->
    if event.data.type is 'nlw-query'
      results = event.data.queries.map(handleQuery)
      postMessage(event.source, event.data.queries, event.data.sourceInfo, results)
    return
  )
  return

export { createQueryHandler }
