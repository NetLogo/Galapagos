# type Edges = { xs: Array[Number], ys: Array[Number], cxs: Array[Number]?, cys: Array[Number]? }
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

# (Snap | null, Snap | null) => Snap | null
closer = (a, b) ->
  if a? and ((not b?) or (Math.abs(a.delta) <= Math.abs(b.delta))) then a else b

# (Edges, Edges, Number) => { x: Snap | null, y: Snap | null }
findSnap = (moving, candidates, threshold = SNAP_DISTANCE) ->
  axis = (edges, centers) ->
    closer(
      findAxisSnap(moving[edges], candidates[edges], threshold)
    , findAxisSnap(moving[centers] ? [], candidates[centers] ? [], threshold)
    )
  { x: axis('xs', 'cxs'), y: axis('ys', 'cys') }

# (Array[Rect]) => Edges
edgesOf = (rects) ->
  {
    xs:  rects.flatMap( (r) -> [r.x, r.x + r.width ] )
  , ys:  rects.flatMap( (r) -> [r.y, r.y + r.height] )
  , cxs: rects.map(     (r) -> Math.round(r.x + r.width  / 2) )
  , cys: rects.map(     (r) -> Math.round(r.y + r.height / 2) )
  }

export { findSnap, edgesOf, SNAP_DISTANCE }
