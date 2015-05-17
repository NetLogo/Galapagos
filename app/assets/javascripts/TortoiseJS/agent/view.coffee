class window.AgentStreamController
  constructor: (@container, fontSize) ->
    @view = new View(fontSize)
    @turtleDrawer = new TurtleDrawer(@view)
    @patchDrawer = new PatchDrawer(@view)
    @spotlightDrawer = new SpotlightDrawer(@view)
    @container.appendChild(@view.visibleCanvas)

    @mouseDown   = false
    @mouseInside = false
    @mouseX      = 0
    @mouseY      = 0
    @initMouseTracking()

    @model = new AgentModel()
    @model.world.turtleshapelist = defaultShapes
    @repaint()

  mouseXcor: => @view.xPixToPcor(@mouseX)
  mouseYcor: => @view.yPixToPcor(@mouseY)

  initMouseTracking: ->
    @view.visibleCanvas.addEventListener('mousedown', (e) => @mouseDown = true)
    document           .addEventListener('mouseup',   (e) => @mouseDown = false)

    @view.visibleCanvas.addEventListener('mouseenter', (e) => @mouseInside = true)
    @view.visibleCanvas.addEventListener('mouseleave', (e) => @mouseInside = false)

    @view.visibleCanvas.addEventListener('mousemove', (e) =>
      rect = @view.visibleCanvas.getBoundingClientRect()
      @mouseX = e.clientX - rect.left
      @mouseY = e.clientY - rect.top
    )

  repaint: ->
    @view.transformToWorld(@model.world)
    @patchDrawer.repaint(@model)
    @turtleDrawer.repaint(@model)
    @spotlightDrawer.repaint(@model)
    @view.repaint(@model)

  applyUpdate: (modelUpdate) ->
    @model.update(modelUpdate)

  update: (modelUpdate) ->
    updates = if Array.isArray(modelUpdate) then modelUpdate else [modelUpdate]
    @applyUpdate(u) for u in updates
    @repaint()


# Perspective constants:
OBSERVE = 0
RIDE    = 1
FOLLOW  = 2
WATCH   = 3

class View
  constructor: (@fontSize) ->
    @canvas = document.createElement('canvas')
    @ctx = @canvas.getContext('2d')
    @visibleCanvas = document.createElement('canvas')
    @visibleCanvas.class = 'netlogo-canvas'
    @visibleCanvas.width = 500
    @visibleCanvas.height = 500
    @visibleCanvas.style.width = "100%"
    @visibleCtx = @visibleCanvas.getContext('2d')

  transformToWorld: (world) ->
    @transformCanvasToWorld(world, @canvas, @ctx)

  transformCanvasToWorld: (world, canvas, ctx) ->
    @quality = if window.devicePixelRatio? then window.devicePixelRatio else 1
    @maxpxcor = if world.maxpxcor? then world.maxpxcor else 25
    @minpxcor = if world.minpxcor? then world.minpxcor else -25
    @maxpycor = if world.maxpycor? then world.maxpycor else 25
    @minpycor = if world.minpycor? then world.minpycor else -25
    @patchsize = if world.patchsize? then world.patchsize else 9
    @wrapX = world.wrappingallowedinx
    @wrapY = world.wrappingallowediny
    @onePixel = 1/@patchsize  # The size of one pixel in patch coords
    @worldWidth = @maxpxcor - @minpxcor + 1
    @worldHeight = @maxpycor - @minpycor + 1
    @worldCenterX = (@maxpxcor + @minpxcor) / 2
    @worldCenterY = (@maxpycor + @minpycor) / 2
    @centerX = @worldWidth / 2
    @centerY = @worldHeight / 2
    canvas.width =  @worldWidth * @patchsize * @quality
    canvas.height = @worldHeight * @patchsize * @quality
    ctx.font = @fontSize + 'px "Lucida Grande", sans-serif'
    ctx.imageSmoothingEnabled = false
    ctx.webkitImageSmoothingEnabled = false
    ctx.mozImageSmoothingEnabled = false
    ctx.oImageSmoothingEnabled = false
    ctx.msImageSmoothingEnabled = false

  usePatchCoordinates: (drawFn) ->
    @ctx.save()
    w = @canvas.width
    h = @canvas.height
    # Argument rows are the standard transformation matrix columns. See spec.
    # http://www.w3.org/TR/2dcontext/#dom-context-2d-transform
    # BCH 5/16/2015
    @ctx.setTransform(w / @worldWidth,                   0,
                      0,                                 -h/@worldHeight,
                      -(@minpxcor-.5) * w / @worldWidth, (@maxpycor+.5) * h / @worldHeight)
    drawFn()
    @ctx.restore()


  offsetX: -> @worldCenterX - @centerX
  offsetY: -> @worldCenterY - @centerY

  # These convert between model coordinates and position in the canvas DOM element
  # This will differ from untransformed canvas position if @quality != 1. BCH 5/6/2015
  xPixToPcor: (x) ->
    (@worldWidth * x / @visibleCanvas.clientWidth + @worldWidth - @offsetX()) % @worldWidth + @minpxcor - .5
  yPixToPcor: (y) ->
    (- @worldHeight * y / @visibleCanvas.clientHeight + 2 * @worldHeight - @offsetY()) % @worldHeight + @minpycor - .5

  # Unlike the above functions, this accounts for @quality. This intentionally does not account
  # for situations like follow (as it's used to make that calculation). BCH 5/6/2015
  xPcorToCanvas: (x) -> (x - @minpxcor + .5) / @worldWidth * @visibleCanvas.width
  yPcorToCanvas: (y) -> (@maxpycor + .5 - y) / @worldHeight * @visibleCanvas.height

  # Wraps text
  drawLabel: (xcor, ycor, label, color) ->
    label = if label? then label.toString() else ''
    if label.length > 0
      @drawWrapped(xcor, ycor, label.length * @fontSize / @onePixel, (x,y) =>
        @ctx.save()
        @ctx.translate(x, y)
        @ctx.scale(@onePixel, -@onePixel)
        @ctx.textAlign = 'end'
        @ctx.fillStyle = netlogoColorToCSS(color)
        @ctx.fillText(label, 0, 0)
        @ctx.restore()
      )

  # drawFn: (xcor, ycor) ->
  drawWrapped: (xcor, ycor, size, drawFn) ->
    xs = if @wrapX then [xcor - @worldWidth,  xcor, xcor + @worldWidth ] else [xcor]
    ys = if @wrapY then [ycor - @worldHeight, ycor, ycor + @worldHeight] else [ycor]
    for x in xs
      if (x + size / 2) > @minpxcor - 0.5 and (x - size / 2) < @maxpxcor + 0.5
        for y in ys
          if (y + size / 2) > @minpycor - 0.5 and (y - size / 2) < @maxpycor + 0.5
            drawFn(x,y)

  # IDs used in watch and follow
  turtleType: 1
  patchType: 2
  linkType: 3

  # Returns the agent being watched, or null.
  watch: (model) ->
    {observer, turtles, links, patches} = model
    if model.observer.perspective != OBSERVE and observer.targetagent and observer.targetagent[1] >= 0
      [type, id] = observer.targetagent
      switch type
        when @turtleType then model.turtles[id]
        when @patchType then model.patches[id]
        when @linkType then model.links[id]
    else
      null

  # Returns the agent being followed, or null.
  follow: (model) ->
    persp = model.observer.perspective
    if persp == FOLLOW or persp == RIDE then @watch(model) else null

  repaint: (model) ->
    target = @follow(model)
    @visibleCanvas.width = @canvas.width
    @visibleCanvas.height = @canvas.height
    if target?
      width = @visibleCanvas.width
      height = @visibleCanvas.height
      @centerX = target.xcor
      @centerY = target.ycor
      x = -@xPcorToCanvas(@centerX) + width / 2
      y = -@yPcorToCanvas(@centerY) + height / 2
      xs = if @wrapX then [x - width,  x, x + width ] else [x]
      ys = if @wrapY then [y - height, y, y + height] else [y]
      for dx in xs
        for dy in ys
          @visibleCtx.drawImage(@canvas, dx, dy)
    else
      @centerX = @worldCenterX
      @centerY = @worldCenterY
      @visibleCtx.drawImage(@canvas, 0, 0)

class Drawer
  constructor: (@view) ->

class SpotlightDrawer extends Drawer
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

  drawSpotlight: (xcor, ycor, size, dimOther) ->
    ctx = @view.ctx
    ctx.lineWidth = @view.onePixel

    ctx.beginPath()
    # Draw arc anti-clockwise so that it's subtracted from the fill. See the
    # fill() documentation and specifically the "nonzero" rule. BCH 3/17/2015
    if dimOther
      @view.drawWrapped(xcor, ycor, size + @outer(), (x, y) =>
        ctx.moveTo(x, y) # Don't want the context to draw a path between the circles. BCH 5/6/2015
        ctx.arc(x, y, (size + @outer()) / 2, 0, 2 * Math.PI, true)
      )
      ctx.rect(@view.minpxcor - 0.5, @view.minpycor - 0.5, @view.worldWidth, @view.worldHeight)
      ctx.fillStyle = @dimmed
      ctx.fill()

    @view.drawWrapped(xcor, ycor, size + @outer(), (x, y) =>
      @drawCircle(x, y, size, size + @outer(), @dimmed)
      @drawCircle(x, y, size, size + @middle(), @spotlightOuterBorder)
      @drawCircle(x, y, size, size + @inner(), @spotlightInnerBorder)
    )

  adjustSize: (size) -> Math.max(size, @view.worldWidth / 16, @view.worldHeight / 16)

  dimensions: (agent) ->
    if agent.xcor?
      [agent.xcor, agent.ycor, 2 * agent.size]
    else if agent.pxcor?
      [agent.pxcor, agent.pycor, 2]
    else
      [agent.midpointx, agent.midpointy, agent.size]

  repaint: (model) ->
    @view.usePatchCoordinates( =>
      watched = @view.watch(model)
      if watched?
        [xcor, ycor, size] = @dimensions(watched)
        @drawSpotlight(xcor, ycor,  @adjustSize(size), model.observer.perspective == WATCH)
    )

class TurtleDrawer extends Drawer
  constructor: (@view) ->
    @turtleShapeDrawer = new CachingShapeDrawer({})
    @linkDrawer = new LinkDrawer(@view, {})

  drawTurtle: (turtle) ->
    if not turtle['hidden?']
      xcor = turtle.xcor
      ycor = turtle.ycor
      size = turtle.size
      @view.drawWrapped(xcor, ycor, size, ((x, y) => @drawTurtleAt(turtle, x, y)))
      @view.drawLabel(xcor + turtle.size / 2, ycor - turtle.size / 2, turtle.label, turtle['label-color'])

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

  drawLink: (link, turtles, wrapX, wrapY) ->
    @linkDrawer.draw(link, turtles, wrapX, wrapY)

  repaint: (model) ->
    world = model.world
    turtles = model.turtles
    links = model.links
    if world.turtleshapelist isnt @turtleShapeDrawer.shapes and world.turtleshapelist?
      @turtleShapeDrawer = new CachingShapeDrawer(world.turtleshapelist)
    if world.linkshapelist isnt @linkDrawer.shapes and world.linkshapelist?
      @linkDrawer = new LinkDrawer(@view, world.linkshapelist)
    @view.usePatchCoordinates( =>
      for id, link of links
        @drawLink(link, turtles, world.wrappingallowedinx, world.wrappingallowediny)
      @view.ctx.lineWidth = @onePixel
      for id, turtle of turtles
        @drawTurtle(turtle)
    )

# Works by creating a scratchCanvas that has a pixel per patch. Those pixels
# are colored accordingly. Then, the scratchCanvas is drawn onto the main
# canvas scaled. This is very, very fast. It also prevents weird lines between
# patches.
class PatchDrawer
  constructor: (@view) ->
    @scratchCanvas = document.createElement('canvas')
    @scratchCtx = @scratchCanvas.getContext('2d')

  colorPatches: (patches) ->
    width = @view.worldWidth
    height = @view.worldHeight
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
    @view.ctx.drawImage(@scratchCanvas, 0, 0, @view.canvas.width, @view.canvas.height)

  labelPatches: (patches) ->
    @view.usePatchCoordinates( =>
      for ignore, patch of patches
        @view.drawLabel(patch.pxcor + .5, patch.pycor - .5, patch.plabel, patch['plabel-color'])
    )

  clearPatches: ->
    @view.ctx.fillStyle = "black"
    @view.ctx.fillRect(0, 0, @view.canvas.width, @view.canvas.height)

  repaint: (model) ->
    world = model.world
    patches = model.patches
    if world.patchesallblack
      @clearPatches()
    else
      @colorPatches(patches)
    if world.patcheswithlabels
      @labelPatches(patches)
