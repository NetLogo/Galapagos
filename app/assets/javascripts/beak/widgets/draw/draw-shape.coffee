import { netlogoColorToOpaqueCSS, netlogoColorToCSS } from "/colors.js"
import { setTransparency, useWrapping } from "./draw-utils.js"

IMAGE_SIZE = 300 # Images are 300x300, in line with netlogo shapes.

# Modifies canvas state.
drawShape = (ctx, onePixel, color, shape = defaultShape, thickness = 1) ->
  ctx.translate(.5, -.5)
  ctx.scale(-1/IMAGE_SIZE, 1/IMAGE_SIZE)
  setTransparency(ctx, color)

  ctx.save()
  ctx.beginPath()
  ctx.rect(0,0,IMAGE_SIZE,IMAGE_SIZE)
  ctx.clip()
  drawRawShape(ctx, onePixel, color, shape, thickness)
  ctx.restore()
  return

# Does not clip. Clipping should be handled by the `drawShape` method that
# calls this. How clipping is performed depends on whether images are being
# cached or not. BCH 7/13/2015
# Modifies canvas state.
drawRawShape = (ctx, onePixel, color, shape = defaultShape, thickness = 1) ->
  ctx.lineWidth = IMAGE_SIZE * onePixel * thickness
  for elem in shape.elements
    draw[elem.type](ctx, color, elem)

setColoring = (ctx, color, element) ->
# Since a turtle's color's transparency applies to its whole shape,  and not
# just the parts that use its default color, we want to use the opaque
# version of its color so we can use global transparency on it. BCH 12/10/2014
  color = netlogoColorToOpaqueCSS(color)
  if element.filled
    if element.marked
      ctx.fillStyle = color
    else
      ctx.fillStyle = element.color
  else
    if element.marked
      ctx.strokeStyle = color
    else
      ctx.strokeStyle = element.color
  return

drawPath = (ctx, color, element) ->
  setColoring(ctx, color, element)
  if element.filled
    ctx.fill()
  else
    ctx.stroke()
  return

draw = {
  circle: (ctx, color, circle) ->
    r = circle.diam/2
    ctx.beginPath()
    ctx.arc(circle.x+r, circle.y+r, r, 0, 2*Math.PI, false)
    ctx.closePath()
    drawPath(ctx, color, circle)
    return

  polygon: (ctx, color, polygon) ->
    xcors = polygon.xcors
    ycors = polygon.ycors
    ctx.beginPath()
    ctx.moveTo(xcors[0], ycors[0])
    for x, i in xcors[1...]
      y = ycors[i+1]
      ctx.lineTo(x, y)
    ctx.closePath()
    drawPath(ctx, color, polygon)
    return

  rectangle: (ctx, color, rectangle) ->
    x = rectangle.xmin
    y = rectangle.ymin
    w = rectangle.xmax - x
    h = rectangle.ymax - y
    setColoring(ctx, color, rectangle)
    if rectangle.filled
      ctx.fillRect(x,y,w,h)
    else
      ctx.strokeRect(x,y,w,h)
    return

  line: (ctx, color, line) ->
    x = line.x1
    y = line.y1
    w = line.x2 - line.x1
    h = line.y2 - line.y1
    setColoring(ctx, color, line)
    # Note that this is 1/20 the size of the image. Smaller this, and the
    # lines are hard to see in most cases.
    ctx.beginPath()
    ctx.moveTo(line.x1, line.y1)
    ctx.lineTo(line.x2, line.y2)
    ctx.stroke()
    return
}

defaultShape = {
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

drawTurtle = (worldShape, shapelist, ctx, turtle, isStamp, fontSize, font) ->
  if not turtle['hidden?']
    { xcor, ycor, size } = turtle
    useWrapping(
      worldShape, ctx, xcor, ycor, size,
      ((ctx, x, y) => drawTurtleAt(shapelist, ctx, worldShape.onePixel, turtle, x, y))
    )
    if not isStamp
      drawLabel(
        worldShape,
        ctx,
        xcor + turtle.size / 2,
        ycor - turtle.size / 2,
        turtle.label,
        turtle['label-color'],
        fontSize,
        font
      )

drawTurtleAt = (shapelist, ctx, onePixel, turtle, xcor, ycor) ->
  heading = turtle.heading
  scale = turtle.size
  angle = (180-heading)/360 * 2*Math.PI
  shapeName = turtle.shape
  shape = shapelist[shapeName] or defaultShape
  ctx.save()
  ctx.translate(xcor, ycor)
  if shape.rotate
    ctx.rotate(angle)
  else
    ctx.rotate(Math.PI)
  ctx.scale(scale, scale)
  drawShape(ctx, onePixel, turtle.color, shape, 1 / scale)
  ctx.restore()

drawLabel = (worldShape, ctx, xcor, ycor, label, color, fontSize, font = '"Lucida Grande", sans-serif') ->
  label = if label? then label.toString() else ''
  if label.length > 0
    useWrapping(worldShape, ctx, xcor, ycor, label.length * fontSize / worldShape.onePixel, (ctx, x, y) =>
      ctx.save()
      ctx.translate(x, y)
      ctx.scale(worldShape.onePixel, -worldShape.onePixel)
      ctx.font = "#{fontSize}px #{font}"
      ctx.textAlign = 'left'
      ctx.fillStyle = netlogoColorToCSS(color)
      # This magic 1.2 value is a pretty good guess for width/height ratio for most fonts. The 2D context does not
      # give a way to get height directly, so this quick and dirty method works fine.  -Jeremy B April 2023
      lineHeight   = ctx.measureText("M").width * 1.2
      lines        = label.split("\n")
      lineWidths   = lines.map( (line) -> ctx.measureText(line).width )
      maxLineWidth = Math.max(lineWidths...)
      # This magic 1.5 value is to get the alignment to mirror what happens in desktop relatively closely.  Without
      # it, labels are too far out to the "right" of the agent since the origin of the text drawing is calculated
      # differently there.  -Jeremy B April 2023
      xOffset      = -1 * (maxLineWidth + 1) / 1.5
      lines.forEach( (line, i) ->
        yOffset = i * lineHeight
        ctx.fillText(line, xOffset, yOffset)
      )
      ctx.restore()
    )

export {
  drawShape,
  draw,
  drawTurtle,
  defaultShape,
  drawLabel
}
