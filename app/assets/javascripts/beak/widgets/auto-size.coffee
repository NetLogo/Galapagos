# type Size          = { width: Number, height: Number }
# type PreferredSize = { width: Number | null, height: Number | null }

GRID_SIZE = 5

# (Number) => Number
ceilToGrid = (n) ->
  Math.ceil(n / GRID_SIZE) * GRID_SIZE

# ({ current: Size, preferred: PreferredSize, preferredBefore: PreferredSize | null, isNew: Boolean
#  , canResize: { width: Boolean, height: Boolean }, minimums: Size }) => Size
autoSizedDims = ({ current, preferred, preferredBefore, isNew, canResize, minimums }) ->

  resolve = (dim) ->
    want = preferred[dim]
    if (not canResize[dim]) or (not want?) or (want is current[dim])
      current[dim]
    else if isNew
      Math.max(minimums[dim], ceilToGrid(want))
    else if preferredBefore? and (preferredBefore[dim] isnt want) and (want > current[dim])
      ceilToGrid(want)
    else
      current[dim]

  { width: resolve('width'), height: resolve('height') }

# (HTMLElement, "width" | "height") => Number
measureNatural = (element, dim) ->
  original           = element.style[dim]
  element.style[dim] = if dim is 'width' then 'max-content' else 'auto'
  size               = if dim is 'width' then element.offsetWidth else element.offsetHeight
  element.style[dim] = original
  size

export { autoSizedDims, measureNatural }
