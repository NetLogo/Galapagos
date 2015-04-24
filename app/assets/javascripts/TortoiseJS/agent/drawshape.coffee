IMAGE_SIZE = 300 # Images are 300x300, in line with netlogo shapes.
LINE_WIDTH = .1 * IMAGE_SIZE

class window.ShapeDrawer
  constructor: (shapes) ->
    @shapes = shapes

  setTransparency: (ctx, turtleColor) ->
    ctx.globalAlpha = if turtleColor.length > 3 then turtleColor[3] / 255 else 1

  drawShape: (ctx, turtleColor, shapeName, thickness = 1) ->
    ctx.translate(.5, -.5)
    ctx.scale(-1/IMAGE_SIZE, 1/IMAGE_SIZE)
    @setTransparency(ctx, turtleColor)
    @drawRawShape(ctx, turtleColor, shapeName, thickness)
    return

  drawRawShape: (ctx, turtleColor, shapeName, thickness = 1) ->
    ctx.lineWidth = LINE_WIDTH * thickness
    shape = @shapes[shapeName] or defaultShape
    for elem in shape.elements
      draw[elem.type](ctx, turtleColor, elem)
    return

class window.CachingShapeDrawer extends ShapeDrawer
  constructor: (shapes) ->
    # Maps (shape name, color) -> canvas
    # Shape/color combinations are pre-rendered to these canvases so they can be
    # quickly rendered to display.
    #
    # If memory is a problem, this can be turned into FIFO, LRU, or LFU cache.
    # Alternatively, each turtle could have it's own personal image pre-rendered.
    # This should be overall better, though, since it will perform well even if
    # turtles are constantly changing shape or color.
    super(shapes)
    @shapeCache = {}

  drawShape: (ctx, turtleColor, shapeName) ->
    shapeName = shapeName.toLowerCase()
    shapeKey = @shapeKey(shapeName, turtleColor)
    shapeCanvas = @shapeCache[shapeKey]
    if not shapeCanvas?
      shapeCanvas = document.createElement('canvas')
      shapeCanvas.width = shapeCanvas.height = IMAGE_SIZE
      shapeCtx = shapeCanvas.getContext('2d')
      @drawRawShape(shapeCtx, turtleColor, shapeName)
      @shapeCache[shapeKey] = shapeCanvas
    ctx.translate(.5, -.5)
    ctx.scale(-1/IMAGE_SIZE, 1/IMAGE_SIZE)
    @setTransparency(ctx, turtleColor)
    ctx.drawImage(shapeCanvas, 0, 0)
    return

  shapeKey: (shapeName, turtleColor) ->
    [shapeName, netlogoColorToOpaqueCSS(turtleColor)]

setColoring = (ctx, turtleColor, element) ->
# Since a turtle's color's transparency applies to its whole shape,  and not
# just the parts that use its default color, we want to use the opaque
# version of its color so we can use global transparency on it. BCH 12/10/2014
  turtleColor = netlogoColorToOpaqueCSS(turtleColor)
  if element.filled
    if element.marked
      ctx.fillStyle = turtleColor
    else
      ctx.fillStyle = element.color
  else
    if element.marked
      ctx.strokeStyle = turtleColor
    else
      ctx.strokeStyle = element.color
  return

drawPath = (ctx, turtleColor, element) ->
  setColoring(ctx, turtleColor, element)
  if element.filled
    ctx.fill()
  else
    ctx.stroke()
  return

window.draw =
  circle: (ctx, turtleColor, circle) ->
    r = circle.diam/2
    ctx.beginPath()
    ctx.arc(circle.x+r, circle.y+r, r, 0, 2*Math.PI, false)
    ctx.closePath()
    drawPath(ctx, turtleColor, circle)
    return

  polygon: (ctx, turtleColor, polygon) ->
    xcors = polygon.xcors
    ycors = polygon.ycors
    ctx.beginPath()
    ctx.moveTo(xcors[0], ycors[0])
    for x, i in xcors[1...]
      y = ycors[i+1]
      ctx.lineTo(x, y)
    ctx.closePath()
    drawPath(ctx, turtleColor, polygon)
    return

  rectangle: (ctx, turtleColor, rectangle) ->
    x = rectangle.xmin
    y = rectangle.ymin
    w = rectangle.xmax - x
    h = rectangle.ymax - y
    setColoring(ctx, turtleColor, rectangle)
    if rectangle.filled
      ctx.fillRect(x,y,w,h)
    else
      ctx.strokeRect(x,y,w,h)
    return

  line: (ctx, turtleColor, line) ->
    x = line.x1
    y = line.y1
    w = line.x2 - line.x1
    h = line.y2 - line.y1
    setColoring(ctx, turtleColor, line)
    # Note that this is 1/20 the size of the image. Smaller this, and the
    # lines are hard to see in most cases.
    ctx.beginPath()
    ctx.moveTo(line.x1, line.y1)
    ctx.lineTo(line.x2, line.y2)
    ctx.stroke()
    return

window.defaultShape = {
  rotate: true
  elements: [
    {
      type: 'polygon'
      color: 'grey'
      filled: 'true'
      marked: 'true'
      xcors: [150, 40, 150, 260]
      ycors: [5, 250, 205, 250]
    }
  ]
}
