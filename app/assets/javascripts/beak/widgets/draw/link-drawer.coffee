import { netlogoColorToCSS } from "/colors.js"
import { drawShape, drawLabel } from "./draw-shape.js"

class Line
  constructor: (@x1, @y1, @x2, @y2) ->

  midpoint: ->
    midpointX = (@x1 + @x2) / 2
    midpointY = (@y1 + @y2) / 2
    [midpointX, midpointY]

traceCurvedLine = (x1, y1, x2, y2, cx, cy, ctx) =>
  ctx.moveTo(x1, y1)
  ctx.quadraticCurveTo(cx, cy, x2, y2)

shouldWrapInDim = (canWrap, dimensionSize, cor1, cor2) ->
  distance = Math.abs(cor1 - cor2)
  canWrap and distance > dimensionSize / 2

calculateShortestLineAngle = (x1, y1, x2, y2) ->
  shortestX = Math.min(x1 - x2, x2 - x1)
  shortestY = Math.min(y1 - y2, y2 - y1)
  Math.atan2(shortestY, shortestX)

calculateComps = (x1, y1, x2, y2, size) ->
  # Comps are NetLogo magic. Taken from the source.
  # JTT 5/1/15
  xcomp = (y2 - y1) / size
  ycomp = (x1 - x2) / size
  [xcomp, ycomp]

calculateSublineOffset = (onePixel, centerOffset, thickness, xcomp, ycomp) ->
  thicknessFactor = thickness / onePixel
  xOff = centerOffset * thicknessFactor * xcomp
  yOff = centerOffset * thicknessFactor * ycomp
  [xOff, yOff]

getOffsetSubline = (x1, y1, x2, y2, xOff, yOff) ->
  lx1 = x1 + xOff
  lx2 = x2 + xOff
  ly1 = y1 + yOff
  ly2 = y2 + yOff
  new Line(lx1, ly1, lx2, ly2)

calculateControlPoint = (midpointX, midpointY, curviness, xcomp, ycomp) ->
  controlX  = midpointX - curviness * xcomp
  controlY  = midpointY - curviness * ycomp
  [controlX, controlY]

drawSubline = ({x1, y1, x2, y2}, dashPattern, thickness, color, isCurved, controlX, controlY, ctx, onePixel) ->
  ctx.save()
  ctx.beginPath()

  ctx.setLineDash(dashPattern.map((x) => x * onePixel))
  ctx.strokeStyle = netlogoColorToCSS(color)
  ctx.lineWidth   = thickness

  ctx.lineCap = if isCurved then 'round' else 'square'

  traceCurvedLine(x1, y1, x2, y2, controlX, controlY, ctx)

  ctx.stroke()

  ctx.setLineDash([1, 0])
  ctx.restore()

drawLinkShape = (x, y, cx, cy, heading, color, thickness, linkShape, shape, ctx, onePixel) ->
  ctx.save()

  theta = calculateShortestLineAngle(x, y, cx, cy)

  shiftCoefficientX = if x - cx > 0 then -1 else 1
  shiftCoefficientY = if y - cy > 0 then -1 else 1

  shift = onePixel * 20
  sx    = x + shift * Math.abs(Math.cos(theta)) * shiftCoefficientX
  sy    = y + shift * Math.abs(Math.sin(theta)) * shiftCoefficientY

  shapeTheta = Math.atan2(sy - y, sx - x) - Math.PI / 2

  ctx.translate(sx, sy)

  if linkShape['direction-indicator'].rotate
    ctx.rotate(shapeTheta)
  else
    ctx.rotate(Math.PI)

  # one pixel should == one patch (before scale) -- JTT 4/15/15
  thicknessFactor = thickness / onePixel

  if thickness <= 1
    scale         = 1 / onePixel / 5
    realThickness = thickness * 10
  else
    scale         = thicknessFactor / 2
    realThickness = 0.5

  ctx.scale(scale, scale)

  drawShape(ctx, onePixel, color, shape, realThickness)

  ctx.restore()

drawLinkLabel = (worldShape, x, y, labelText, color, ctx, fontSize, font) ->
  drawLabel(worldShape, ctx, x - 3 * worldShape.onePixel, y + 3 * worldShape.onePixel, labelText, color, fontSize, font)

drawLink = (shapelist, link, end1, end2, worldShape, ctx, fontSize, font, isStamp = false) ->
  if not link['hidden?']
    { color, thickness } = link
    { xcor: x1, ycor: y1 } = end1
    { xcor: x2, ycor: y2 } = end2
    { onePixel, wrapX, wrapY, worldWidth, worldHeight } = worldShape

    theta = calculateShortestLineAngle(x1, y1, x2, y2)

    adjustedThickness = if thickness > onePixel then thickness else onePixel # LOL?

    wrapX = shouldWrapInDim(wrapX, worldWidth,  x1, x2)
    wrapY = shouldWrapInDim(wrapY, worldHeight, y1, y2)

    getWrappedLines(x1, y1, x2, y2, worldShape, wrapX, wrapY)
    .forEach(drawLinkLine(shapelist, worldShape, link, adjustedThickness, ctx, isStamp, fontSize, font))

drawLinkLine = (
  shapelist,
  worldShape,
  { color, size, heading, 'directed?': isDirected, shape: shapeName, label, 'label-color': labelColor },
  thickness,
  ctx,
  isStamp,
  fontSize,
  font
) => ({ x1, y1, x2, y2 }) =>

  shape = shapelist[shapeName]
  { curviness, lines } = shape

  lines.forEach(
    (line) =>

      # Draw the middle line last so the arrow shape will always be on top
      [0, 2, 1].forEach(
        (i) =>

          { 'x-offset': centerOffset, 'dash-pattern': dashPattern, 'is-visible': visible } = lines[i]

          isMiddleLine = i is 1

          [xcomp, ycomp] = calculateComps(x1, y1, x2, y2, size)
          [xOff, yOff]   = calculateSublineOffset(worldShape.onePixel, centerOffset, thickness, xcomp, ycomp)
          offsetSubline  = getOffsetSubline(x1, y1, x2, y2, xOff, yOff)

          [midpointX, midpointY] = offsetSubline.midpoint()
          [controlX,  controlY]  = calculateControlPoint(midpointX, midpointY, curviness, xcomp, ycomp)

          if visible
            isCurved = curviness > 0
            drawSubline(
              offsetSubline,
              dashPattern,
              thickness,
              color,
              isCurved,
              controlX,
              controlY,
              ctx,
              worldShape.onePixel
            )

          if isMiddleLine
            if isDirected and size > (.25 * worldShape.onePixel)
              dirIndicator = shape['direction-indicator']
              oneP         = worldShape.onePixel
              drawLinkShape(x2, y2, controlX, controlY, heading, color, thickness, shape, dirIndicator, ctx, oneP)

            hasLabel = label?
            if hasLabel and not isStamp
              drawLinkLabel(worldShape, controlX, controlY, label, labelColor, ctx, fontSize, font)

      )
  )

getWrappedLines = (x1, y1, x2, y2, worldShape, lineWrapsX, lineWrapsY) ->
  { worldWidth, worldHeight } = worldShape

  if lineWrapsX and lineWrapsY
    if x1 < x2
      if y1 < y2
        [
          new Line(x1, y1, x2 - worldWidth, y2 - worldHeight),
          new Line(x1 + worldWidth, y1, x2, y2 - worldHeight),
          new Line(x1 + worldWidth, y1 + worldHeight, x2, y2),
          new Line(x1, y1 + worldHeight, x2 - worldWidth, y2)
        ]
      else
        [
          new Line(x1, y1, x2 - worldWidth, y2 + worldHeight),
          new Line(x1 + worldWidth, y1, x2, y2 + worldHeight),
          new Line(x1 + worldWidth, y1 - worldHeight, x2, y2),
          new Line(x1, y1 - worldHeight, x2 - worldWidth, y2)
        ]
    else
      if y1 < y2
        [
          new Line(x1, y1, x2 + worldWidth, y2 - worldHeight),
          new Line(x1 - worldWidth, y1, x2, y2 - worldHeight),
          new Line(x1 - worldWidth, y1 + worldHeight, x2, y2),
          new Line(x1, y1 + worldHeight, x2 + worldWidth, y2)
        ]
      else
        [
          new Line(x1, y1, x2 + worldWidth, y2 + worldHeight),
          new Line(x1 - worldWidth, y1, x2, y2 + worldHeight),
          new Line(x1 - worldWidth, y1 - worldHeight, x2, y2),
          new Line(x1, y1 - worldHeight, x2 + worldWidth, y2)
        ]
  else if lineWrapsX
    if x1 < x2
      [
        new Line(x1, y1, x2 - worldWidth, y2),
        new Line(x1 + worldWidth, y1, x2, y2)
      ]
    else
      [
        new Line(x1, y1, x2 + worldWidth, y2),
        new Line(x1 - worldWidth, y1, x2, y2)
      ]
  else if lineWrapsY
    if y1 < y2
      [
        new Line(x1, y1, x2, y2 - worldHeight),
        new Line(x1, y1 + worldHeight, x2, y2)
      ]
    else
      [
        new Line(x1, y1 - worldHeight, x2, y2),
        new Line(x1, y1, x2, y2 + worldHeight)
      ]
  else
    [ new Line(x1, y1, x2, y2) ]

export {
  Line,
  drawLink
}
