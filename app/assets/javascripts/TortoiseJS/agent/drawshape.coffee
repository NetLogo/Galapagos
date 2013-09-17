class window.ShapeDrawer
  constructor: (shapes) ->
    @shapes = shapes

  drawShape: (ctx, turtleColor, shapeName) ->
    ctx.translate(.5, -.5)
    ctx.scale(-1/300, 1/300)
    @drawRawShape(ctx, turtleColor, shapeName)
    return

  drawRawShape: (ctx, turtleColor, shapeName) ->
    shape = @shapes[shapeName] or defaultShape
    for elem in shape.elements
      draw[elem.type](ctx, turtleColor, elem)
    return

class window.CachingShapeDrawer extends ShapeDrawer
  constructor: (shapes) ->
    # Maps (shape name, color) -> canvas
    # Canvas are 300x300, in line with netlogo shapes.
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
    shapeCanvas = @shapeCache[[shapeName, turtleColor]]
    if not shapeCanvas?
      shapeCanvas = document.createElement('canvas')
      shapeCanvas.width = shapeCanvas.height = 300
      shapeCtx = shapeCanvas.getContext('2d')
      @drawRawShape(shapeCtx, turtleColor, shapeName)
      @shapeCache[[shapeName, turtleColor]] = shapeCanvas
    ctx.translate(.5, -.5)
    ctx.scale(-1/300, 1/300)
    ctx.drawImage(shapeCanvas, 0, 0)
    return

setColoring = (ctx, turtleColor, element) ->
  turtleColor = netlogoColorToCSS(turtleColor)
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
    ctx.lineWidth = 15 
    ctx.beginPath()
    ctx.moveTo(line.x1, line.y1)
    ctx.lineTo(line.x2, line.y2)
    ctx.stroke()
    ctx.lineWidth = .1
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
