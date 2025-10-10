# { [k: number]: WidgetController } } -> Array<{ widget: WidgetController, key: number }>
# Sort widgets by physical location while preserving their object keys.
# Since widgets are indexed by their position in the original array,
# we need to maintain a way to access their original ordering.
# - Omar I (Oct 10 2025)
export sortWidgetObjects = (widgetObj) ->
  result = Object.values(widgetObj)
    .map((widget, index) -> {widget, key: index})
    .sort(({ widget: widgetA}, { widget: widgetB }) ->
      { x: axcor, y: aycor, width: aw, height: ah } = widgetA
      { x: bxcor, y: bycor, width: bw, height: bh } = widgetB
      # row-major order
      if aycor isnt bycor then aycor - bycor
      else if axcor isnt bxcor then axcor - bxcor
      else if aw isnt bw then aw - bw
      else if ah isnt bh then ah - bh
      else 0
    )
  return result
