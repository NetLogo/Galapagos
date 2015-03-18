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
    @onePixel = 1/@patchsize  # The size of one pixel in patch coords
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
    @drawer = new CachingShapeDrawer({})

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
    shape = @drawer.shapes[shapeName] or defaultShape
    ctx.save()
    ctx.translate(xcor, ycor)
    if shape.rotate
      ctx.rotate(angle)
    else
      ctx.rotate(Math.PI)
    ctx.scale(scale, scale)
    @drawer.drawShape(ctx, turtle.color, shapeName)
    ctx.restore()
    @view.drawLabel(turtle.label, turtle['label-color'], xcor + turtle.size / 2, ycor - turtle.size / 2)

  drawLine: (x1,y1,x2,y2) ->
    @view.ctx.moveTo(x1,y1)
    @view.ctx.lineTo(x2,y2)

  drawLink: (link, turtles, canWrapX, canWrapY) ->
    ctx = @view.ctx

    shouldWrapInDim = (canWrap, dimensionSize, cor1, cor2) ->
      distance = Math.abs(cor1 - cor2)
      canWrap and distance > dimensionSize / 2

    adjustLinkEnds = (end1Cor, end2Cor, trigShift, minForExtending, maxForExtending) ->
      diff = Math.abs(link.thickness * trigShift) / 2
      if minForExtending < link.heading < maxForExtending
        [end1Cor + diff, end2Cor - diff]
      else
        [end1Cor - diff, end2Cor + diff]

    if not link['hidden?']
      { xcor: e1x, ycor: e1y } = turtles[link.end1]
      { xcor: e2x, ycor: e2y } = turtles[link.end2]

      wrapX = shouldWrapInDim(canWrapX, @view.patchWidth,  e1x, e2x)
      wrapY = shouldWrapInDim(canWrapY, @view.patchHeight, e1y, e2y)

      if link.thickness is @view.onePixel
        x1 = e1x
        x2 = e2x
        y1 = e1y
        y2 = e2y
      else
        shortestX = Math.min(e1x - e2x, e2x - e1x)
        shortestY = Math.min(e1y - e2y, e2y - e1y)
        theta     = Math.atan2(shortestY, shortestX)

        [x1, x2] = adjustLinkEnds(e1x, e2x, Math.cos(theta), 180, 360)
        [y1, y2] = adjustLinkEnds(e1y, e2y, Math.sin(theta), 90,  270)

      ctx.strokeStyle = netlogoColorToCSS(link.color)
      ctx.lineWidth = if link.thickness > @view.onePixel then link.thickness else @view.onePixel
      ctx.beginPath()

      patchWidth = @view.patchWidth
      patchHeight = @view.patchHeight
      if wrapX and wrapY
        # Unnecessary lines are drawn here since we're not checking to see which
        # are actually on screen. However, browsers are better at these checks
        # than we are and will ignore offscreen stuff. Thus, we shouldn't bother
        # checking unless we see a consistent performance improvement. Note that
        # at least 3 lines will be needed in the majority of cases and 4 lines
        # are necessary in certain cases. -- BCH (3/30/2014)
        if x1 < x2
          if y1 < y2
            @drawLine(x1, y1, x2 - patchWidth, y2 - patchHeight)
            @drawLine(x1 + patchWidth, y1, x2, y2 - patchHeight)
            @drawLine(x1 + patchWidth, y1 + patchHeight, x2, y2)
            @drawLine(x1, y1 + patchHeight, x2 - patchWidth, y2)
          else
            @drawLine(x1, y1, x2 - patchWidth, y2 + patchHeight)
            @drawLine(x1 + patchWidth, y1, x2, y2 + patchHeight)
            @drawLine(x1 + patchWidth, y1 - patchHeight, x2, y2)
            @drawLine(x1, y1 - patchHeight, x2 - patchWidth, y2)
        else
          if y1 < y2
            @drawLine(x1, y1, x2 + patchWidth, y2 - patchHeight)
            @drawLine(x1 - patchWidth, y1, x2, y2 - patchHeight)
            @drawLine(x1 - patchWidth, y1 + patchHeight, x2, y2)
            @drawLine(x1, y1 + patchHeight, x2 + patchWidth, y2)
          else
            @drawLine(x1, y1, x2 + patchWidth, y2 + patchHeight)
            @drawLine(x1 - patchWidth, y1, x2, y2 + patchHeight)
            @drawLine(x1 - patchWidth, y1 - patchHeight, x2, y2)
            @drawLine(x1, y1 - patchHeight, x2 + patchWidth, y2)
      else if wrapX
        if x1 < x2
          @drawLine(x1, y1, x2 - patchWidth, y2)
          @drawLine(x1 + patchWidth, y1, x2, y2)
        else
          @drawLine(x1, y1, x2 + patchWidth, y2)
          @drawLine(x1 - patchWidth, y1, x2, y2)
      else if wrapY
        if y1 < y2
          @drawLine(x1, y1, x2, y2 - patchHeight)
          @drawLine(x1, y1 + patchHeight, x2, y2)
        else
          @drawLine(x1, y1 - patchHeight, x2, y2)
          @drawLine(x1, y1, x2, y2 + patchHeight)
      else
        @drawLine(x1, y1, x2, y2)

    ctx.stroke()

  repaint: (model) ->
    world = model.world
    turtles = model.turtles
    links = model.links
    if world.turtleshapelist != @drawer.shapes and typeof world.turtleshapelist == "object"
      @drawer = new CachingShapeDrawer(world.turtleshapelist)
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

