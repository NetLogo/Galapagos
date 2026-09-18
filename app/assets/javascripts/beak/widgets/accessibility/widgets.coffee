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
# WidgetObject -> Array<{ widget: WidgetController, key: string }>
export sortWidgetObjects = (widgetObj) ->
  # Sort widgets by physical location while preserving their object keys.  The keys start out as positions in the
  # original array, but deleting a widget leaves a gap in them, so they have to be carried along rather than
  # recalculated from the sorted order.
  # - Omar I (Oct 10 2025), Jeremy B (Sep 2026)
  return Object.entries(widgetObj)
    .map(([key, widget]) -> { widget, key })
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
