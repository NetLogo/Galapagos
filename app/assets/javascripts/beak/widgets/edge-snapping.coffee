# type Edges = { xs: Array[Number], ys: Array[Number] }
# type Snap  = { delta: Number, at: Number }

SNAP_DISTANCE = 5

# (Array[Number], Array[Number], Number) => Snap | null
findAxisSnap = (moving, candidates, threshold) ->
  best = null
  for m in moving
    for c in candidates
      delta = c - m
      if (Math.abs(delta) <= threshold) and ((not best?) or (Math.abs(delta) < Math.abs(best.delta)))
        best = { delta, at: c }
  best

# (Edges, Edges, Number) => { x: Snap | null, y: Snap | null }
findSnap = (moving, candidates, threshold = SNAP_DISTANCE) ->
  { x: findAxisSnap(moving.xs, candidates.xs, threshold), y: findAxisSnap(moving.ys, candidates.ys, threshold) }

# (Array[Rect]) => Edges
edgesOf = (rects) ->
  { xs: rects.flatMap( (r) -> [r.x, r.x + r.width] ), ys: rects.flatMap( (r) -> [r.y, r.y + r.height] ) }

export { findSnap, edgesOf, SNAP_DISTANCE }
