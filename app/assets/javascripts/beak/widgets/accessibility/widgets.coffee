# Rect: { x, y, width, height }
# (Rect, Rect) -> Int (comparison result)
export comparePositionsRowMajor = (a, b) ->
  { x: axcor, y: aycor, width: aw, height: ah } = a
  { x: bxcor, y: bycor, width: bw, height: bh } = b
  if aycor isnt bycor
    aycor - bycor
  else if axcor isnt bxcor
    axcor - bxcor
  else if aw isnt bw
    aw - bw
  else if ah isnt bh
    ah - bh
  else
    0

# WidgetObject: { [k: number]: WidgetController } }
# WidgetObject -> Array<{ widget: WidgetController, key: number }>
export sortWidgetObjects = (widgetObj) ->
  # Sort widgets by physical location while preserving their object keys.
  # Since widgets are indexed by their position in the original array,
  # we need to maintain a way to access their original ordering.
  # - Omar I (Oct 10 2025)
  return Object.values(widgetObj)
    .map((widget, index) -> {widget, key: index})
    .sort(({ widget: a}, { widget: b }) ->
      comparePositionsRowMajor(a, b)
    )

# WidgetObject -> WidgetObject
export setSortingKeys = (widgetObj) ->
  # Add a `sortingKey` property to each widget in the object,
  # indicating its position in row-major order.
  sorted = sortWidgetObjects(widgetObj)
  sorted.forEach(({ widget, key }, index) ->
    widgetObj[key].sortingKey = index
  )
  return widgetObj
