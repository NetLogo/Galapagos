# Rect: { x, y, width, height }
# Rect -> Rect -> Int (comparison result)
export comparePositionsRowMajor = (a, b) ->
  { x: axcor, y: aycor, width: aw, height: ah } = a
  { x: bxcor, y: bycor, width: bw, height: bh } = b
  if aycor isnt bycor then aycor - bycor
  else if axcor isnt bxcor then axcor - bxcor
  else if aw isnt bw then aw - bw
  else if ah isnt bh then ah - bh
  else 0

# { [k: number]: WidgetController } } -> Array<{ widget: WidgetController, key: number }>
# Sort widgets by physical location while preserving their object keys.
# Since widgets are indexed by their position in the original array,
# we need to maintain a way to access their original ordering.
# - Omar I (Oct 10 2025)
export sortWidgetObjects = (widgetObj) ->
  return Object.values(widgetObj)
    .map((widget, index) -> {widget, key: index})
    .sort(({ widget: a}, { widget: b }) ->
      comparePositionsRowMajor(a, b)
    )

# Add a `sortingKey` property to each widget in the object,
# indicating its position in row-major order.
export setSortingKeys = (widgetObj) ->
  sorted = sortWidgetObjects(widgetObj)
  sorted.forEach(({ widget, key }, index) ->
    widgetObj[key].sortingKey = index
  )
  return widgetObj
