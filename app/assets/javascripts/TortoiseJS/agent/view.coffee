class window.AgentStreamController
  constructor: (@container, fontSize) ->
    @view = new View(fontSize)
    @turtleDrawer = new TurtleDrawer(@view)
    @patchDrawer = new PatchDrawer(@view)
    @spotlightDrawer = new SpotlightDrawer(@view)
    @container.appendChild(@view.canvas)

    @mouseDown   = false
    @mouseInside = false
    @mouseXcor   = 0
    @mouseYcor   = 0
    @initMouseTracking()

    @model = new AgentModel()
    @model.world.turtleshapelist = defaultShapes
    @repaint()

  initMouseTracking: ->
    # Using spotlightView because it's on top. BCH 10/21/2014
    @view.canvas.addEventListener('mousedown', (e) => @mouseDown = true)
    document      .addEventListener('mouseup',   (e) => @mouseDown = false)

    @view.canvas.addEventListener('mouseenter', (e) => @mouseInside = true)
    @view.canvas.addEventListener('mouseleave', (e) => @mouseInside = false)

    @view.canvas.addEventListener('mousemove', (e) =>
      rect = @view.canvas.getBoundingClientRect()
      @mouseXcor = @view.xPixToPcor(e.clientX - rect.left)
      @mouseYcor = @view.yPixToPcor(e.clientY - rect.top)
    )

  repaint: ->
    @view.transformToWorld(@model.world)
    @patchDrawer.repaint(@model)
    @turtleDrawer.repaint(@model)
    @spotlightDrawer.repaint(@model)

  applyUpdate: (modelUpdate) ->
    @model.update(modelUpdate)

  update: (modelUpdate) ->
    updates = if Array.isArray(modelUpdate) then modelUpdate else [modelUpdate]
    @applyUpdate(u) for u in updates
    @repaint()

class View
  constructor: (@fontSize) ->
    @canvas = document.createElement('canvas')
    @canvas.class = 'netlogo-canvas'
    @canvas.width = 500
    @canvas.height = 500
    @canvas.style.width = "100%"
    @ctx = @canvas.getContext('2d')

  transformToWorld: (world) ->
    quality = if window.devicePixelRatio? then window.devicePixelRatio else 1
    @maxpxcor = if world.maxpxcor? then world.maxpxcor else 25
    @minpxcor = if world.minpxcor? then world.minpxcor else -25
    @maxpycor = if world.maxpycor? then world.maxpycor else 25
    @minpycor = if world.minpycor? then world.minpycor else -25
    @patchsize = if world.patchsize? then world.patchsize else 9
    @onePixel = 1 / @patchsize  # The size of one pixel in patch coords
    @patchWidth = @maxpxcor - @minpxcor + 1
    @patchHeight = @maxpycor - @minpycor + 1
    @canvas.width =  @patchWidth * @patchsize * quality
    @canvas.height = @patchHeight * @patchsize * quality
    # Argument rows are the matrix columns. See spec.
    @ctx.setTransform(@canvas.width/@patchWidth, 0,
                      0, -@canvas.height/@patchHeight,
                      -(@minpxcor-.5)*@canvas.width/@patchWidth,
                      (@maxpycor+.5)*@canvas.height/@patchHeight)
    @ctx.font = @fontSize + 'px "Lucida Grande", sans-serif'
    @ctx.imageSmoothingEnabled = false
    @ctx.webkitImageSmoothingEnabled = false
    @ctx.mozImageSmoothingEnabled = false
    @ctx.oImageSmoothingEnabled = false
    @ctx.msImageSmoothingEnabled = false

  xPixToPcor: (x) -> @minpxcor - .5 + @patchWidth * x / @canvas.offsetWidth
  yPixToPcor: (y) -> @maxpycor + .5 - @patchHeight * y / @canvas.offsetHeight

  drawLabel: (label, color, x, y) ->
    label = if label? then label.toString() else ''
    if label.length > 0
      @ctx.save()
      @ctx.translate(x, y)
      @ctx.scale(1/@patchsize, -1/@patchsize)
      @ctx.textAlign = 'end'
      @ctx.fillStyle = netlogoColorToCSS(color)
      @ctx.fillText(label, 0, 0)
      @ctx.restore()

  # IDs used in watch and follow
  turtleType: 1
  patchType: 2
  linkType: 3

  # Returns the agent being watched, or null.
  watch: (model) ->
    {observer, turtles, links, patches} = model
    if observer.perspective > 0 and observer.targetagent and observer.targetagent[1] >= 0
      [type, id] = observer.targetagent
      switch type
        when @turtleType then model.turtles[id]
        when @patchType then model.patches[id]
        when @linkType then model.links[id]
    else
      null

  # Returns the agent being followed, or null.
  follow: (model) ->
    if model.observer.perspective == 2 then watch(model) else null


class SpotlightDrawer
  constructor: (@view) ->

  # Names and values taken from org.nlogo.render.SpotlightDrawer
  dimmed: "rgba(0, 0, 50, #{ 100 / 255 })"
  spotlightInnerBorder: "rgba(200, 255, 255, #{ 100 / 255 })"
  spotlightOuterBorder: "rgba(200, 255, 255, #{ 50 / 255 })"
  clear: 'white'  # for clearing with 'destination-out' compositing

  outer: -> 10 / @view.patchsize
  middle: -> 8 / @view.patchsize
  inner: -> 4 / @view.patchsize

  drawCircle: (x, y, innerDiam, outerDiam, color) ->
    ctx = @view.ctx
    ctx.fillStyle = color
    ctx.beginPath()
    ctx.arc(x, y, outerDiam / 2, 0, 2 * Math.PI)
    ctx.arc(x, y, innerDiam / 2, 0, 2 * Math.PI, true)
    ctx.fill()

  drawSpotlight: (x, y, size) ->
    ctx = @view.ctx
    ctx.lineWidth = @view.onePixel

    ctx.beginPath()
    # Draw arc anti-clockwise so that it's subtracted from the fill. See the
    # fill() documentation and specifically the "nonzero" rule. BCH 3/17/2015
    ctx.arc(x, y, (size + @outer()) / 2, 0, 2 * Math.PI, true)
    ctx.rect(@view.minpxcor - 0.5, @view.minpycor - 0.5, @view.patchWidth, @view.patchHeight)
    ctx.fillStyle = @dimmed
    ctx.fill()

    @drawCircle(x, y, size, size + @outer(), @dimmed)
    @drawCircle(x, y, size, size + @middle(), @spotlightOuterBorder)
    @drawCircle(x, y, size, size + @inner(), @spotlightInnerBorder)

  adjustSize: (size) -> Math.max(size, @view.patchWidth / 16, @view.patchHeight / 16)

  dimensions: (agent) ->
    if agent.xcor?
      [agent.xcor, agent.ycor, 2 * agent.size]
    else if agent.pxcor?
      [agent.pxcor, agent.pycor, 2]
    else
      [agent.midpointx, agent.midpointy, agent.size]

  repaint: (model) ->
    watched = @view.watch(model)
    if watched?
      [xcor, ycor, size] = @dimensions(watched)
      @drawSpotlight(xcor, ycor,  @adjustSize(size))

class TurtleDrawer
  constructor: (@view) ->
    @turtleShapeDrawer = new CachingShapeDrawer({})
    @linkDrawer = new LinkDrawer(@view, {})

  drawTurtle: (turtle, canWrapX, canWrapY) ->
    if not turtle['hidden?']
      xcor = turtle.xcor
      ycor = turtle.ycor
      size = turtle.size
      @drawTurtleAt(turtle, xcor, ycor)
      if canWrapX
        if xcor - size < @minpxcor
          @drawTurtleAt(turtle, xcor + @patchWidth, ycor)
        # Note that these CANNOT be `else if`s. Large turtles can wrap on both
        # sides. -- BCH (3/30/2014)
        if xcor + size > @maxpxcor
          @drawTurtleAt(turtle, xcor - @patchWidth, ycor)
      if canWrapY
        if ycor - size < @minpycor
          @drawTurtleAt(turtle, xcor, ycor + @patchHeight)
        if ycor + size > @maxpycor
          @drawTurtleAt(turtle, xcor, ycor - @patchHeight)

  drawTurtleAt: (turtle, xcor, ycor) ->
    ctx = @view.ctx
    heading = turtle.heading
    scale = turtle.size
    angle = (180-heading)/360 * 2*Math.PI
    shapeName = turtle.shape
    shape = @turtleShapeDrawer.shapes[shapeName] or defaultShape
    ctx.save()
    ctx.translate(xcor, ycor)
    if shape.rotate
      ctx.rotate(angle)
    else
      ctx.rotate(Math.PI)
    ctx.scale(scale, scale)
    @turtleShapeDrawer.drawShape(ctx, turtle.color, shapeName)
    ctx.restore()
    @view.drawLabel(turtle.label, turtle['label-color'], xcor + turtle.size / 2, ycor - turtle.size / 2)

  drawLink: (link, turtles, wrapX, wrapY) ->
    @linkDrawer.draw(link, turtles, wrapX, wrapY)

  repaint: (model) ->
    world = model.world
    turtles = model.turtles
    links = model.links
    if world.turtleshapelist isnt @turtleShapeDrawer.shapes and typeof world.turtleshapelist is "object"
      @turtleShapeDrawer = new CachingShapeDrawer(world.turtleshapelist)
    if world.linkshapelist isnt @linkDrawer.shapes and typeof world.linkshapelist is "object"
      @linkDrawer = new LinkDrawer(@view, world.linkshapelist)
    for id, link of links
      @drawLink(link, turtles, world.wrappingallowedinx, world.wrappingallowediny)
    @view.ctx.lineWidth = @onePixel
    for id, turtle of turtles
      @drawTurtle(turtle, world.wrappingallowedinx, world.wrappingallowediny)
    return

# Works by creating a scratchCanvas that has a pixel per patch. Those pixels
# are colored accordingly. Then, the scratchCanvas is drawn onto the main
# canvas scaled. This is very, very fast. It also prevents weird lines between
# patches.
class PatchDrawer
  constructor: (@view) ->
    @scratchCanvas = document.createElement('canvas')
    @scratchCtx = @scratchCanvas.getContext('2d')

  colorPatches: (patches) ->
    width = @view.patchWidth
    height = @view.patchHeight
    minX = @view.minpxcor
    maxX = @view.maxpxcor
    minY = @view.minpycor
    maxY = @view.maxpycor
    @scratchCanvas.width = width
    @scratchCanvas.height = height
    imageData = @scratchCtx.createImageData(width,height)
    numPatches = ((maxY - minY)*width + (maxX - minX)) * 4
    for i in [0...numPatches]
      patch = patches[i]
      if patch?
        j = 4 * i
        [r,g,b] = netlogoColorToRGB(patch.pcolor)
        imageData.data[j+0] = r
        imageData.data[j+1] = g
        imageData.data[j+2] = b
        imageData.data[j+3] = 255
    @scratchCtx.putImageData(imageData, 0, 0)
    # translate so scale flips the image at the right point
    trans = minY + maxY
    ctx = @view.ctx
    ctx.translate(0, trans)
    ctx.scale(1,-1)
    ctx.drawImage(@scratchCanvas, minX - .5, minY - .5, width, height)
    ctx.scale(1,-1)
    ctx.translate(0, -trans)

  labelPatches: (patches) ->
    for ignore, patch of patches
      @view.drawLabel(patch.plabel, patch['plabel-color'], patch.pxcor + .5, patch.pycor - .5)

  clearPatches: ->
    @view.ctx.fillStyle = "black"
    @view.ctx.fillRect(@view.minpxcor - .5, @view.minpycor - .5, @view.patchWidth, @view.patchHeight)

  repaint: (model) ->
    world = model.world
    patches = model.patches
    if world.patchesallblack
      @clearPatches()
    else
      @colorPatches(patches)
    if world.patcheswithlabels
      @labelPatches(patches)


class Line
  constructor: (@x1, @y1, @x2, @y2) ->

  midpoint: ->
    midpointX = (@x1 + @x2) / 2
    midpointY = (@y1 + @y2) / 2
    [midpointX, midpointY]

class LinkDrawer
  constructor: (@view, @shapes) ->
    directionIndicators = {}
    for name, shape of @shapes
      directionIndicators[name] = shape['direction-indicator']
    @linkShapeDrawer = new ShapeDrawer(directionIndicators)

  drawCurvedLine: (x1, y1, x2, y2, cx, cy) =>
    @view.ctx.moveTo(x1, y1)
    @view.ctx.quadraticCurveTo(cx, cy, x2, y2)

  drawLine: (x1, y1, x2, y2) =>
    @view.ctx.moveTo(x1, y1)
    @view.ctx.lineTo(x2, y2)

  shouldWrapInDim: (canWrap, dimensionSize, cor1, cor2) ->
    distance = Math.abs(cor1 - cor2)
    canWrap and distance > dimensionSize / 2

  adjustLinkEnds: (link, end1Cor, end2Cor, trigShift, minForExtending, maxForExtending) ->
    diff = Math.abs(link.thickness * trigShift) / 2
    if minForExtending < link.heading < maxForExtending
      [end1Cor + diff, end2Cor - diff]
    else
      [end1Cor - diff, end2Cor + diff]

  calculateLineAngle: (x1, y1, x2, y2) ->
    shortestX = Math.min(x1 - x2, x2 - x1)
    shortestY = Math.min(y1 - y2, y2 - y1)
    Math.atan2(shortestY, shortestX)

  calculateComps: (x1, y1, x2, y2, size) ->
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
    controlX  = midpointX + curviness * xcomp
    controlY  = midpointY + curviness * ycomp
    [controlX, controlY]

  drawSubline: ({x1, y1, x2, y2}, dashPattern, controlX, controlY) ->
    @view.ctx.setLineDash(dashPattern.map((x) => x * @view.onePixel))
    @view.ctx.beginPath()

    if controlX? and controlY?
      @drawCurvedLine(x1, y1, x2, y2, controlX, controlY)
    else
      @drawLine(x1, y1, x2, y2)

    @view.ctx.stroke()
    @view.ctx.setLineDash([1, 0])

  drawShape: (x1, y1, x2, y2, heading, color, thickness, linkShape, shapeName) ->
    @view.ctx.save()

    theta = @calculateLineAngle(x2, y2, x1, y1)

    shiftCoefficientX = if x1 - x2 > 0 then -1 else 1
    shiftCoefficientY = if y1 - y2 > 0 then -1 else 1

    shift = @view.onePixel * 20
    sx    = x1 + shift * Math.abs(Math.cos(theta)) * shiftCoefficientX
    sy    = y1 + shift * Math.abs(Math.sin(theta)) * shiftCoefficientY

    shapeTheta = Math.atan2(sy - y1, sx - x1) - Math.PI / 2

    @view.ctx.translate(sx, sy)

    if linkShape['direction-indicator'].rotate
      @view.ctx.rotate(shapeTheta)
    else
      @view.ctx.rotate(Math.PI)

    # Magic numbers c/o Esther -- JTT, JAB 4/13/15
    scalingFactor = 4

    onePixelThickness = 1 / scalingFactor / scalingFactor

    # one pixel should == one patch (before scale) -- JTT 4/15/15
    thickness = onePixelThickness * thickness / @view.onePixel

    @view.ctx.scale(scalingFactor, scalingFactor)

    @linkShapeDrawer.drawShape(@view.ctx, color, shapeName, thickness)

    @view.ctx.restore()

  draw: (link, turtles, canWrapX, canWrapY) ->
    if not link['hidden?']
      { end1, end2, color, thickness } = link
      { xcor: e1x, ycor: e1y } = turtles[end1]
      { xcor: e2x, ycor: e2y } = turtles[end2]

      theta = @calculateLineAngle(e1x, e1y, e2x, e2y)

      if thickness <= @view.onePixel
        x1 = e1x
        x2 = e2x
        y1 = e1y
        y2 = e2y
        adjustedThickness = @view.onePixel
      else
        [x1, x2] = @adjustLinkEnds(link, e1x, e2x, Math.cos(theta), 180, 360)
        [y1, y2] = @adjustLinkEnds(link, e1y, e2y, Math.sin(theta), 90,  270)
        adjustedThickness = thickness

      @view.ctx.strokeStyle = netlogoColorToCSS(color)
      @view.ctx.lineWidth   = adjustedThickness

      wrapX = @shouldWrapInDim(canWrapX, @view.patchWidth,  e1x, e2x)
      wrapY = @shouldWrapInDim(canWrapY, @view.patchHeight, e1y, e2y)

      @getWrappedLines(x1, y1, x2, y2, wrapX, wrapY).forEach(@_drawLinkLine(link, adjustedThickness))

  _drawLinkLine: ({ color, size, heading, 'directed?': isDirected, shape: shapeName }, thickness) => ({ x1, y1, x2, y2 }) =>

    linkShape = @shapes[shapeName]
    { curviness, lines } = linkShape

    lines.forEach(
      (line) =>

        { 'x-offset': centerOffset, 'dash-pattern': dashPattern, 'is-visible': visible } = line

        if visible

          [xcomp, ycomp] = @calculateComps(x1, y1, x2, y2, size)
          [xOff, yOff]   = @calculateSublineOffset(centerOffset, thickness, xcomp, ycomp)
          offsetSubline  = @getOffsetSubline(x1, y1, x2, y2, xOff, yOff)
          isCurved       = curviness > 0
          isMiddleLine   = line is lines[1]

          if isCurved

            [midpointX, midpointY] = offsetSubline.midpoint()
            [controlX,  controlY]  = @calculateControlPoint(midpointX, midpointY, curviness, xcomp, ycomp)

          @drawSubline(offsetSubline, dashPattern, controlX, controlY)

          if isMiddleLine and isDirected
            if isCurved
              @drawShape(x1, y1, controlX, controlY, heading, color, thickness, linkShape, shapeName)
            else
              @drawShape(x1, y1, x2, y2, heading, color, thickness, linkShape, shapeName)

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
