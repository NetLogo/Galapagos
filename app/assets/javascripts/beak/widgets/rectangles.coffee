# type Rect = { x: Number, y: Number, width: Number, height: Number }

# (Number, Number, Number, Number) => Rect
rectFromCorners = (x1, y1, x2, y2) ->
  x      = Math.min(x1, x2)
  y      = Math.min(y1, y2)
  width  = Math.abs(x2 - x1)
  height = Math.abs(y2 - y1)
  { x, y, width, height }

# (Rect, Rect) => Boolean
rectsTouch = (a, b) ->
  (a.x <= b.x + b.width) and (b.x <= a.x + a.width) and (a.y <= b.y + b.height) and (b.y <= a.y + a.height)

export { rectFromCorners, rectsTouch }
