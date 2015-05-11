class Line
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
    @linkShapeDrawer = new ShapeDrawer(directionIndicators)

  traceCurvedLine: (x1, y1, x2, y2, cx, cy) =>
    @view.ctx.moveTo(x1, y1)
    @view.ctx.quadraticCurveTo(cx, cy, x2, y2)

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

  drawSubline: ({x1, y1, x2, y2}, dashPattern, thickness, color, isCurved, controlX, controlY) ->
    @view.ctx.save()
    @view.ctx.beginPath()

    @view.ctx.setLineDash(dashPattern.map((x) => x * @view.onePixel))
    @view.ctx.strokeStyle = netlogoColorToCSS(color)
    @view.ctx.lineWidth   = thickness

    @view.ctx.lineCap = if isCurved then 'round' else 'square'

    @traceCurvedLine(x1, y1, x2, y2, controlX, controlY, thickness, color, dashPattern)

    @view.ctx.stroke()

    @view.ctx.setLineDash([1, 0])
    @view.ctx.restore()

  drawShape: (x, y, cx, cy, heading, color, thickness, linkShape, shapeName) ->
    @view.ctx.save()

    theta = @calculateShortestLineAngle(x, y, cx, cy)

    shiftCoefficientX = if x - cx > 0 then -1 else 1
    shiftCoefficientY = if y - cy > 0 then -1 else 1

    shift = @view.onePixel * 20
    sx    = x + shift * Math.abs(Math.cos(theta)) * shiftCoefficientX
    sy    = y + shift * Math.abs(Math.sin(theta)) * shiftCoefficientY

    shapeTheta = Math.atan2(sy - y, sx - x) - Math.PI / 2

    @view.ctx.translate(sx, sy)

    if linkShape['direction-indicator'].rotate
      @view.ctx.rotate(shapeTheta)
    else
      @view.ctx.rotate(Math.PI)

    # one pixel should == one patch (before scale) -- JTT 4/15/15
    thicknessFactor = thickness / @view.onePixel

    # 8 is just a nice number. Seems to look right. -- JTT 5/8/15
    # According to NetLogo, scalingFactor "has no hidden meaning."
    # This seems to work, so... close enough. -- clarification. JTT 5/11/15
    friendlyMagicScalingNumber = 8

    # If there's a more elegant way to do this, I'm open to suggestion. -- JTT 5/8/15
    if thicknessFactor < friendlyMagicScalingNumber
      thickness = 1 / (1 + friendlyMagicScalingNumber - thicknessFactor)
      thickness = if thickness < 2 / friendlyMagicScalingNumber then 2 / friendlyMagicScalingNumber else thickness
      scale     = friendlyMagicScalingNumber
    else
      thickness = 1
      scale = thicknessFactor

    @view.ctx.scale(scale / 2, scale / 2)

    @linkShapeDrawer.drawShape(@view.ctx, color, shapeName, thickness)

    @view.ctx.restore()

  drawLabel: (x, y, labelText, color) ->
    @view.ctx.save()

    @view.ctx.translate(x - 3*@view.onePixel, y + 3*@view.onePixel)
    @view.ctx.scale(@view.onePixel, -@view.onePixel)
    @view.ctx.textAlign = 'end'
    @view.ctx.fillStyle = netlogoColorToCSS(color)
    @view.ctx.fillText(labelText, 0, 0)

    @view.ctx.restore()

  draw: (link, turtles, canWrapX, canWrapY) ->
    if not link['hidden?']
      { end1, end2, color, thickness } = link
      { xcor: x1, ycor: y1 } = turtles[end1]
      { xcor: x2, ycor: y2 } = turtles[end2]

      theta = @calculateShortestLineAngle(x1, y1, x2, y2)

      adjustedThickness = if thickness > @view.onePixel then thickness else @view.onePixel

      wrapX = @shouldWrapInDim(canWrapX, @view.patchWidth,  x1, x2)
      wrapY = @shouldWrapInDim(canWrapY, @view.patchHeight, y1, y2)

      @getWrappedLines(x1, y1, x2, y2, wrapX, wrapY).forEach(@_drawLinkLine(link, adjustedThickness))

  _drawLinkLine: ({ color, size, heading, 'directed?': isDirected, shape: shapeName, label, 'label-color': labelColor }, thickness) => ({ x1, y1, x2, y2 }) =>

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

          @drawSubline(offsetSubline, dashPattern, thickness, color, isCurved, controlX, controlY)

          if isMiddleLine
            if isDirected
              @drawShape(x2, y2, controlX, controlY, heading, color, thickness, linkShape, shapeName)
            if hasLabel
              @drawLabel(controlX, controlY, label, labelColor)

    )

  getWrappedLines: (x1, y1, x2, y2, wrapX, wrapY) ->
    patchWidth = @view.patchWidth
    patchHeight = @view.patchHeight

    if wrapX and wrapY
      if x1 < x2
        if y1 < y2
          [
            new Line(x1, y1, x2 - patchWidth, y2 - patchHeight),
            new Line(x1 + patchWidth, y1, x2, y2 - patchHeight),
            new Line(x1 + patchWidth, y1 + patchHeight, x2, y2),
            new Line(x1, y1 + patchHeight, x2 - patchWidth, y2)
          ]
        else
          [
            new Line(x1, y1, x2 - patchWidth, y2 + patchHeight),
            new Line(x1 + patchWidth, y1, x2, y2 + patchHeight),
            new Line(x1 + patchWidth, y1 - patchHeight, x2, y2),
            new Line(x1, y1 - patchHeight, x2 - patchWidth, y2)
          ]
      else
        if y1 < y2
          [
            new Line(x1, y1, x2 + patchWidth, y2 - patchHeight),
            new Line(x1 - patchWidth, y1, x2, y2 - patchHeight),
            new Line(x1 - patchWidth, y1 + patchHeight, x2, y2),
            new Line(x1, y1 + patchHeight, x2 + patchWidth, y2)
          ]
        else
          [
            new Line(x1, y1, x2 + patchWidth, y2 + patchHeight),
            new Line(x1 - patchWidth, y1, x2, y2 + patchHeight),
            new Line(x1 - patchWidth, y1 - patchHeight, x2, y2),
            new Line(x1, y1 - patchHeight, x2 + patchWidth, y2)
          ]
    else if wrapX
      if x1 < x2
        [
          new Line(x1, y1, x2 - patchWidth, y2),
          new Line(x1 + patchWidth, y1, x2, y2)
        ]
      else
        [
          new Line(x1, y1, x2 + patchWidth, y2),
          new Line(x1 - patchWidth, y1, x2, y2)
        ]
    else if wrapY
      if y1 < y2
        [
          new Line(x1, y1, x2, y2 - patchHeight),
          new Line(x1, y1 + patchHeight, x2, y2)
        ]
      else
        [
          new Line(x1, y1 - patchHeight, x2, y2),
          new Line(x1, y1, x2, y2 + patchHeight)
        ]
    else
      [ new Line(x1, y1, x2, y2) ]
