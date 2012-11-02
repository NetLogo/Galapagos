javaIntColorToHex = (number) ->
  if number < 0
    number = 0xFFFFFF + number + 1
  '#'+number.toString(16)

window.drawShape = (ctx, turtleColor, heading, shape) ->
  ctx.translate(.5, -.5)
  ctx.scale(-1/300, 1/300)
  for elt in shape.elements
    draw[elt.type](ctx, turtleColor, elt)

drawPath = (ctx, turtleColor, element) ->
    if element.filled
      if element.marked
        ctx.fillStyle = turtleColor
      else
        ctx.fillStyle = element.color
      ctx.fill()
    else
      if element.marked
        ctx.strokeStyle = turtleColor
      else
        ctx.strokeStyle = element.color
      ctx.stroke()
    return

window.draw = {
  circle: (ctx, turtleColor, circle) ->
    r = circle.diam/2
    ctx.beginPath()
    ctx.arc(circle.x+r, circle.y+r, r, 0, 2*Math.PI, false)
    ctx.closePath()
    drawPath(ctx, turtleColor, circle)

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
}

window.shapes = {
  default: {
    elements: [
      {
        type: 'polygon',
        color: 'grey',
        filled: 'true',
        marked: 'true',
        xcors: [150, 40, 150, 260],
        ycors: [5, 250, 205, 250]
      }
    ]
  },

  _rtri: {
    elements: [
      {
        type: 'polygon',
        color: 'grey',
        filled: true,
        marked: true,
        xcors: [30, 240, 240, 30],
        ycors: [240, 30, 240, 240]
      }
    ]
  },

  circle: {
    elements: [
      {
        type: 'circle',
        color: 'grey',
        filled: true,
        marked: true,
        x: 0,
        y: 0,
        diam: 300
      }
    ]
  },

  _circles: {
    elements: [
      {
        type: 'circle',
        color: 'green',
        filled: true,
        marked: false,
        x: 171,
        y: 36,
        diam: 108
      }, {
        type: 'circle',
        color: 'red',
        filled: true,
        marked: false,
        x: 56,
        y: 36,
        diam: 67
      }, {
        type: 'circle',
        color: 'blue',
        filled: true,
        marked: false,
        x: 69,
        y: 189,
        diam: 42,
      }, {
        type: 'circle',
        color: 'yellow',
        filled: true,
        marked: false,
        x: 210,
        y: 195,
        diam: 30
      }
    ]
  }
}
