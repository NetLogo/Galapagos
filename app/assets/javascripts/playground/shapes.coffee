window.netlogoColorToCSS = (number) ->
  if number <  10
    "hsl(0, 0%, #{number*10}%)"
  else
    h = Math.round((number-15)/10)*36
    s = 100
    l = 10*(number%10)
    "hsl(#{h}, #{s}%, #{l}%)"

window.drawShape = (ctx, turtleColor, heading, shape) ->
  ctx.translate(.5, -.5)
  ctx.scale(-1/300, 1/300)
  for elt in shape.elements
    draw[elt.type](ctx, turtleColor, elt)

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

window.shapes =
  default:
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
  _rtri: 
    elements: [
      {
        type: 'polygon'
        color: 'grey'
        filled: true
        marked: true,
        xcors: [30, 240, 240, 30]
        ycors: [240, 30, 240, 240]
      }
    ]
  circle:
    rotate: true
    elements: [
      {
        type: 'circle'
        color: 'grey'
        filled: true
        marked: true
        x: 0
        y: 0
        diam: 300
      }
    ]
  _circles:
    elements: [
      {
        type: 'circle'
        color: 'green'
        filled: true
        marked: false
        x: 171
        y: 36
        diam: 108
      }, {
        type: 'circle'
        color: 'red'
        filled: true
        marked: false
        x: 56
        y: 36
        diam: 67
      }, {
        type: 'circle'
        color: 'blue'
        filled: true
        marked: false
        x: 69
        y: 189
        diam: 42
      }, {
        type: 'circle'
        color: 'yellow'
        filled: true
        marked: false
        x: 210
        y: 195
        diam: 30
      }
    ]
  sheep:
    rotate: false
    elements: [
      {type: 'circle', color: '#ffffff', filled: true, marked: true, x: 203, y: 65, diam: 88}
      {type: 'circle', color: '#ffffff', filled: true, marked: true, x: 70, y: 65, diam: 162}
      {type: 'circle', color: '#ffffff', filled: true, marked: true, x: 150, y: 105, diam: 120}
      {type: 'polygon', color: '#8d8d8d', filled: true, marked: false, xcors: [218, 240, 255, 278], ycors: [120, 165, 165, 120]}
      {type: 'circle', color: '#8d8d8d', filled: true, marked: false, x: 214, y: 72, diam: 67}
      {type: 'rectangle', color: '#ffffff', filled: true, marked: true, xmin: 164, ymin: 223, xmax: 179, ymax: 298}
      {type: 'polygon', color: '#ffffff', filled: true, marked: true, xcors: [45, 30, 30, 15, 45], ycors: [285, 285, 240, 195, 210]}
      {type: 'circle', color: '#ffffff', filled: true, marked: true, x: 3, y: 83, diam: 150}
      {type: 'rectangle', color: '#ffffff', filled: true, marked: true, xmin: 65, ymin: 221, xmax: 80, ymax: 296}
      {type: 'polygon', color: '#ffffff', filled: true, marked: true, xcors: [195, 210, 210, 240, 195], ycors: [285, 285, 240, 210, 210]}
      {type: 'polygon', color: '#8d8d8d', filled: true, marked: false, xcors: [276, 285, 302, 294], ycors: [85, 105, 99, 83]}
      {type: 'polygon', color: '#8d8d8d', filled: true, marked: false, xcors: [219, 210, 193, 201], ycors: [85, 105, 99, 83]}
    ]
  wolf:
    rotate: false
    elements: [
      {type: 'polygon', color: '#000000', filled: true, marked: false, xcors: [253, 245, 245], ycors: [133, 131, 133]}
      {type: 'polygon', color: '#8d8d8d', filled: true, marked: true, xcors:[2, 13, 30, 38, 38, 20, 20, 27, 38, 40, 31, 31, 60, 68, 75, 66, 65, 82, 84, 100, 103, 77, 79, 100, 98, 119, 143, 160, 166, 172, 173, 167, 160, 154, 169, 178, 186, 198, 200, 217, 219, 207, 195, 192, 210, 227, 242, 259, 284, 277, 293, 299, 297, 273, 270], ycors: [194, 197, 191, 193, 205, 226, 257, 265, 266, 260, 253, 230, 206, 198, 209, 228, 243, 261, 268, 267, 261, 239, 231, 207, 196, 201, 202, 195, 210, 213, 238, 251, 248, 265, 264, 247, 240, 260, 271, 271, 262, 258, 230, 198, 184, 164, 144, 145, 151, 141, 140, 134, 127, 119, 105]}
      {type: 'polygon', color: '#8d8d8d', filled: true, marked: true, xcors:[-1, 14, 36, 40, 53, 82, 134, 159, 188, 227, 236, 238, 268, 269, 281, 269, 269], ycors:[195, 180, 166, 153, 140, 131, 133, 126, 115, 108, 102, 98, 86, 92, 87, 103, 113]}
    ]
