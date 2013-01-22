window.drawShape = (ctx, turtleColor, heading, shape) ->
  ctx.translate(.5, -.5)
  ctx.scale(-1/300, 1/300)
  for elt in shape.elements
    draw[elt.type](ctx, turtleColor, elt)
  return

setColoring = (ctx, turtleColor, element) ->
  if typeof(turtleColor)=='number'
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

  # TODO: bogus, draw as a rect for now, enough to get Climate Change "ray" shape going,
  # couldn't get it working with actual lines, sigh - ST 12/17/12
  line: (ctx, turtleColor, line) ->
    x = line.x1
    y = line.y1
    w = line.x2 - line.x1
    h = line.y2 - line.y1
    setColoring(ctx, turtleColor, line)
    if line.filled
      ctx.fillRect(x,y,w,h)
    else
      ctx.strokeRect(x,y,w,h)
    return
