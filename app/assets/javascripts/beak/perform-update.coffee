# (Any) => Any
deepClone = (x) ->
  if (not x?) or (typeof(x) in ["number", "string", "boolean"])
    x
  else if Array.isArray(x)
    x.map(deepClone)
  else
    out = {}
    for key, value of x
      out[key] = deepClone(value)
    out

# (Object[Any], Object[Any]) => Object[Any]
mergeObjects = (obj1, obj2) ->

  helper = (x, y) ->
    for key, value of y
      x[key] =
        if x[key]? and (typeof value) is "object" and not Array.isArray(value)
          helper(x[key], value)
        else
          value
    x

  clone1 = deepClone(obj1)
  clone2 = deepClone(obj2)

  helper(clone1, clone2, {})

# (Object[Any], Object[Any]) => Object[Any]
cleanupInstadeaths = (obj1, obj2) ->

  morph = (key, basis, comparator) ->
    if basis[key]?
      out = {}
      for k, v of basis[key] when v.WHO isnt -1 or comparator[key][k]?
       out[k] = v
      out
    else
      basis[key]

  turtles = morph("turtles", obj1, obj2)
  links   = morph(  "links", obj1, obj2)

  if turtles?
    obj1.turtles = turtles

  if links?
    obj1.links = links

  obj1

# (Object[Any], Object[Any]) => Object[Any]
objectDiff = (x, y) ->

  helper = (obj1, obj2) ->

    { eq } = tortoise_require('brazier/equals')

    out = {}

    for key, value of obj1
      key2 = key.toLowerCase()
      if not obj2[key2]?
        out[key] = value
      else if not eq(obj2[key2])(value)
        result =
          if (typeof value) is "object" and not Array.isArray(value)
            helper(value, obj2[key2])
          else
            value
        if result?
          out[key] = result

    if Object.keys(out).length > 0
      out
    else
      undefined

  helper(x, y) ? {}

# (WidgetController, HNWSession, Boolean, Boolean) => Unit
performUpdate = (widgetController, hnw, isFullUpdate, shouldRepaint) ->

  viewUpdates =
    if isFullUpdate and Updater.hasUpdates()
      Updater.collectUpdates()
    else
      []

  f = (acc, x) -> (acc ? []).concat(x ? [])

  drawingUpdates = viewUpdates.map((vu) -> vu.drawingEvents).reduce(f, [])
  viewUpdates.forEach((vu) -> delete vu.drawingEvents)

  mergedUpdate = viewUpdates.reduce(mergeObjects, {})
  if drawingUpdates.length > 0
    mergedUpdate.drawingEvents = drawingUpdates

  naiveDiff = objectDiff(mergedUpdate, widgetController.viewController.model)

  diffedUpdate = cleanupInstadeaths(naiveDiff, widgetController.viewController.model)

  if Object.keys(diffedUpdate).length > 0
    widgetController.redraw([diffedUpdate])

  if shouldRepaint
    widgetController.viewController.repaint()

  hnw.performUpdate(diffedUpdate)

  return

export default performUpdate
