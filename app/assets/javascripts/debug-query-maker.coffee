defaultQueries = Object.freeze([
  { type: 'globals' }
  { type: 'reporter', code: 'patches'}
  { type: 'widgets' }
  { type: 'info' }
  { type: 'code' }
  { type: 'nlogo-file'}
])

defaultQueriesByType = Object.freeze(defaultQueries.reduce( (queriesSoFar, query) ->
  queriesSoFar.set(query.type, query)
  queriesSoFar
, new Map()))

clone = (oldObject) ->
  JSON.parse(JSON.stringify(oldObject))

createQueryMaker = (modelContainer) ->
  queryCount = -1
  (type, args) ->
    queryCount = (queryCount + 1)
    sourceInfo = "query-number-#{queryCount}"
    query = clone(defaultQueriesByType.get(type))
    if args? then Object.assign(query, args)
    modelContainer.contentWindow.postMessage({
      type:       'nlw-query'
    , queries:    [query]
    , sourceInfo: sourceInfo
    }, '*')

    sourceInfo

listenForQueryResponses = () ->
  window.addEventListener('message', (event) ->
    if (event.data.type is 'nlw-query-response')
      console.log(event.data)
    return
  )
  return

export { listenForQueryResponses, createQueryMaker }
