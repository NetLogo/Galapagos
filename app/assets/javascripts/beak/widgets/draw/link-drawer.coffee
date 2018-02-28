class window.Line
  constructor: (@x1, @y1, @x2, @y2) ->

  midpoint: ->
    midpointX = (@x1 + @x2) / 2
    midpointY = (@y1 + @y2) / 2
    [midpointX, midpointY]

class window.LinkDrawer
  constructor: (@view, @shapes) ->
    directionIndicators = {}
    for name, shape of @shapes
      directionIndicators[name] = shape['direction-indicator']
    @linkShapeDrawer = new ShapeDrawer(directionIndicators, @view.onePixel)

  traceCurvedLine: (x1, y1, x2, y2, cx, cy, ctx) =>
    ctx.moveTo(x1, y1)
    ctx.quadraticCurveTo(cx, cy, x2, y2)

  shouldWrapInDim: (canWrap, dimensionSize, cor1, cor2) ->
    distance = Math.abs(cor1 - cor2)
    canWrap and distance > dimensionSize / 2

  calculateShortestLineAngle: (x1, y1, x2, y2) ->
    shortestX = Math.min(x1 - x2, x2 - x1)
    shortestY = Math.min(y1 - y2, y2 - y1)
    Math.atan2(shortestY, shortestX)

  calculateComps: (x1, y1, x2, y2, size) ->
    # Comps are NetLogo magic. Taken from the source.
    # JTT 5/1/15
    xcomp = (y2 - y1) / size
    ycomp = (x1 - x2) / size
    [xcomp, ycomp]

  calculateSublineOffset: (centerOffset, thickness, xcomp, ycomp) ->
    thicknessFactor = thickness / @view.onePixel
    xOff = centerOffset * thicknessFactor * xcomp
    yOff = centerOffset * thicknessFactor * ycomp
    [xOff, yOff]

  getOffsetSubline: (x1, y1, x2, y2, xOff, yOff) ->
    lx1 = x1 + xOff
    lx2 = x2 + xOff
    ly1 = y1 + yOff
    ly2 = y2 + yOff
    new Line(lx1, ly1, lx2, ly2)

  calculateControlPoint: (midpointX, midpointY, curviness, xcomp, ycomp) ->
    controlX  = midpointX - curviness * xcomp
    controlY  = midpointY - curviness * ycomp
    [controlX, controlY]

  drawSubline: ({x1, y1, x2, y2}, dashPattern, thickness, color, isCurved, controlX, controlY, ctx) ->
    ctx.save()
    ctx.beginPath()

    ctx.setLineDash(dashPattern.map((x) => x * @view.onePixel))
    ctx.strokeStyle = netlogoColorToCSS(color)
    ctx.lineWidth   = thickness

    ctx.lineCap = if isCurved then 'round' else 'square'

    @traceCurvedLine(x1, y1, x2, y2, controlX, controlY, ctx)

    ctx.stroke()

    ctx.setLineDash([1, 0])
    ctx.restore()

  drawShape: (x, y, cx, cy, heading, color, thickness, linkShape, shapeName, ctx) ->
    ctx.save()

    theta = @calculateShortestLineAngle(x, y, cx, cy)

    shiftCoefficientX = if x - cx > 0 then -1 else 1
    shiftCoefficientY = if y - cy > 0 then -1 else 1

    shift = @view.onePixel * 20
    sx    = x + shift * Math.abs(Math.cos(theta)) * shiftCoefficientX
    sy    = y + shift * Math.abs(Math.sin(theta)) * shiftCoefficientY

    shapeTheta = Math.atan2(sy - y, sx - x) - Math.PI / 2

    ctx.translate(sx, sy)

    if linkShape['direction-indicator'].rotate
      ctx.rotate(shapeTheta)
    else
      ctx.rotate(Math.PI)

    # one pixel should == one patch (before scale) -- JTT 4/15/15
    thicknessFactor = thickness / @view.onePixel
    
    if thickness <= 1
      scale         = 1 / @view.onePixel / 5
      realThickness = thickness * 10
    else
      scale         = thicknessFactor / 2
      realThickness = 0.5

    ctx.scale(scale, scale)

    @linkShapeDrawer.drawShape(ctx, color, shapeName, realThickness)

    ctx.restore()

  drawLabel: (x, y, labelText, color) ->
    @view.drawLabel(x - 3 * @view.onePixel, y + 3 * @view.onePixel, labelText, color)

  draw: (link, end1, end2, canWrapX, canWrapY, ctx = @view.ctx, isStamp = false) ->
    if not link['hidden?']
      { color, thickness } = link
      { xcor: x1, ycor: y1 } = end1
      { xcor: x2, ycor: y2 } = end2

      theta = @calculateShortestLineAngle(x1, y1, x2, y2)

      adjustedThickness = if thickness > @view.onePixel then thickness else @view.onePixel

      wrapX = @shouldWrapInDim(canWrapX, @view.worldWidth,  x1, x2)
      wrapY = @shouldWrapInDim(canWrapY, @view.worldHeight, y1, y2)

      @getWrappedLines(x1, y1, x2, y2, wrapX, wrapY).forEach(@_drawLinkLine(link, adjustedThickness, ctx, isStamp))

  _drawLinkLine: ({ color, size, heading, 'directed?': isDirected, shape: shapeName, label, 'label-color': labelColor },
                  thickness, ctx, isStamp) => ({ x1, y1, x2, y2 }) =>

    linkShape = @shapes[shapeName]
    { curviness, lines } = linkShape

    lines.forEach(
      (line) =>

        { 'x-offset': centerOffset, 'dash-pattern': dashPattern, 'is-visible': visible } = line

        if visible

          [xcomp, ycomp] = @calculateComps(x1, y1, x2, y2, size)
          [xOff, yOff]   = @calculateSublineOffset(centerOffset, thickness, xcomp, ycomp)
          offsetSubline  = @getOffsetSubline(x1, y1, x2, y2, xOff, yOff)
          isMiddleLine   = line is lines[1]
          isCurved       = curviness > 0
          hasLabel       = label?

          [midpointX, midpointY] = offsetSubline.midpoint()

          [controlX,  controlY]  = @calculateControlPoint(midpointX, midpointY, curviness, xcomp, ycomp)

          @drawSubline(offsetSubline, dashPattern, thickness, color, isCurved, controlX, controlY, ctx)

          if isMiddleLine
            if isDirected and size > (.25 * @view.onePixel)
              @drawShape(x2, y2, controlX, controlY, heading, color, thickness, linkShape, shapeName, ctx)
            if hasLabel and not isStamp
              @drawLabel(controlX, controlY, label, labelColor)

    )

  getWrappedLines: (x1, y1, x2, y2, lineWrapsX, lineWrapsY) ->
    worldWidth = @view.worldWidth
    worldHeight = @view.worldHeight

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
