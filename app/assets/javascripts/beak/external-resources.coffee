# () => Array[ExternalResource]
serializeResources = () ->
  Object.keys(workspace.resources).map( (key) ->
      o = workspace.resources[key]
      { name: key, extension: o.extension, data: o.data }
    )

export { serializeResources }
