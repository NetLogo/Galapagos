class window.AgentStreamController
  constructor: (@container, fontSize) ->
    @spotlightView = new SpotlightView(fontSize)
    @turtleView = new TurtleView(fontSize)
    @patchView = new PatchView(fontSize)
    @layers = new LayerView(fontSize, [@patchView, @turtleView, @spotlightView])
    @container.appendChild(@layers.canvas)

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
    @layers.canvas.addEventListener('mousedown', (e) => @mouseDown = true)
    document      .addEventListener('mouseup',   (e) => @mouseDown = false)

    @layers.canvas.addEventListener('mouseenter', (e) => @mouseInside = true)
    @layers.canvas.addEventListener('mouseleave', (e) => @mouseInside = false)

    @layers.canvas.addEventListener('mousemove', (e) =>
      rect = @layers.canvas.getBoundingClientRect()
      @mouseXcor = @layers.xPixToPcor(e.clientX - rect.left)
      @mouseYcor = @layers.yPixToPcor(e.clientY - rect.top)
    )

  repaint: ->
    @spotlightView.repaint(@model)
    @turtleView.repaint(@model)
    @patchView.repaint(@model)
    @layers.repaint(@model)

  applyUpdate: (modelUpdate) ->
    @model.update(modelUpdate)

  update: (modelUpdate) ->
    updates = if Array.isArray(modelUpdate) then modelUpdate else [modelUpdate]
    @applyUpdate(u) for u in updates
    @repaint()

class View
  constructor: (@fontSize) ->
    # Have size = 1 actually be patch-size pixels results in worse quality
    # for turtles. `quality` scales the number of pixels used. It should be as
    # small as possible as overly large canvases can crash computers
    @quality = 1
    @canvas = document.createElement('canvas')
    @canvas.class = 'netlogo-canvas'
    @canvas.width = 500
    @canvas.height = 500
    @canvas.style.width = "100%"
    @ctx = @canvas.getContext('2d')

  matchesWorld: (world) ->
    (@maxpxcor? and @minpxcor? and @maxpycor? and @minpycor? and @patchsize?) and
      (not world.maxpxcor? or world.maxpxcor == @maxpxcor) and
      (not world.minpxcor? or world.minpxcor == @minpxcor) and
      (not world.maxpycor? or world.maxpycor == @maxpycor) and
      (not world.minpycor? or world.minpycor == @minpycor) and
      (not world.patchsize? or world.patchsize == @patchsize)

  transformToWorld: (world) ->
    @maxpxcor = if world.maxpxcor? then world.maxpxcor else 25
    @minpxcor = if world.minpxcor? then world.minpxcor else -25
    @maxpycor = if world.maxpycor? then world.maxpycor else 25
    @minpycor = if world.minpycor? then world.minpycor else -25
    @patchsize = if world.patchsize? then world.patchsize else 9
    @onePixel = 1/@patchsize  # The size of one pixel in patch coords
    @patchWidth = @maxpxcor - @minpxcor + 1
    @patchHeight = @maxpycor - @minpycor + 1
    @canvas.width =  @patchWidth * @patchsize * @quality
    @canvas.height = @patchHeight * @patchsize * @quality
    # Argument rows are the matrix columns. See spec.
    @ctx.setTransform(@canvas.width/@patchWidth, 0,
                      0, -@canvas.height/@patchHeight,
                      -(@minpxcor-.5)*@canvas.width/@patchWidth,
                      (@maxpycor+.5)*@canvas.height/@patchHeight)
    @ctx.font = @fontSize + 'px "Lucida Grande", sans-serif'

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


class LayerView extends View
  constructor: (@fontSize, @layers) ->
    super(@fontSize)
    @quality = Math.max.apply(null, (l.quality for l in @layers))

  repaint: (model) ->
    @transformToWorld(model.world)
    @ctx.setTransform(1, 0, 0, 1, 0, 0) # Disable transform since we're drawing pixel data
    for view in @layers
      @ctx.drawImage(view.canvas, 0, 0, @canvas.width, @canvas.height)


class SpotlightView extends View
  # Names and values taken from org.nlogo.render.SpotlightDrawer
  dimmed: "rgba(0, 0, 50, #{ 100 / 255 })"
  spotlightInnerBorder: "rgba(200, 255, 255, #{ 100 / 255 })"
  spotlightOuterBorder: "rgba(200, 255, 255, #{ 50 / 255 })"
  clear: 'white'  # for clearing with 'destination-out' compositing

  outer: -> 10 / @patchsize
  middle: -> 8 / @patchsize
  inner: -> 4 / @patchsize

  drawCircle: (x, y, diam, color) ->
    @ctx.fillStyle = color
    @ctx.beginPath()
    @ctx.arc(x, y, diam / 2, 0, 2 * Math.PI)
    @ctx.fill()

  drawSpotlight: (x, y, size) ->
    @ctx.lineWidth = @onePixel
    @ctx.globalCompositeOperation = 'source-over'
    @ctx.fillStyle = @dimmed
    @ctx.fillRect(@minpxcor - 0.5, @minpycor - 0.5, @patchWidth, @patchHeight)

    @ctx.globalCompositeOperation = 'destination-out'
    @drawCircle(x, y, size + @outer(), @clear)

    @ctx.globalCompositeOperation = 'source-over'
    @drawCircle(x, y, size + @outer(), @dimmed)
    @drawCircle(x, y, size + @middle(), @spotlightOuterBorder)
    @drawCircle(x, y, size + @inner(), @spotlightInnerBorder)

    @ctx.globalCompositeOperation = 'destination-out'
    @drawCircle(x, y, size, @clear)

  adjustSize: (size) -> Math.max(size, @patchWidth / 16, @patchHeight / 16)

  dimensions: (agent) ->
    if agent.xcor?
      [agent.xcor, agent.ycor, 2 * agent.size]
    else if agent.pxcor?
      [agent.pxcor, agent.pycor, 2]
    else
      [agent.midpointx, agent.midpointy, agent.size]

  repaint: (model) ->
    @transformToWorld(model.world)
    watched = @watch(model)
    if watched?
      [xcor, ycor, size] = @dimensions(watched)
      @drawSpotlight(xcor, ycor,  @adjustSize(size))

class TurtleView extends View
  constructor: (fontSize) ->
    super(fontSize)
    @drawer = new CachingShapeDrawer({})
    # Using quality = 1 here results in very pixelated turtles when using the
    # CachingShapeDrawer, something weird about the turtle image scaling.
    # Higher quality here seems preserved even when the LayeredView is
    # quality = 1.
    # quality = 3 was arrived at empirically. I noticed no improvement after 3.
    @quality = 3

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
    heading = turtle.heading
    scale = turtle.size
    angle = (180-heading)/360 * 2*Math.PI
    shapeName = turtle.shape
    shape = @drawer.shapes[shapeName] or defaultShape
    @ctx.save()
    @ctx.translate(xcor, ycor)
    if shape.rotate
      @ctx.rotate(angle)
    else
      @ctx.rotate(Math.PI)
    @ctx.scale(scale, scale)
    @drawer.drawShape(@ctx, turtle.color, shapeName)
    @ctx.restore()
    @drawLabel(turtle.label, turtle['label-color'], xcor + turtle.size / 2, ycor - turtle.size / 2)

  drawLine: (x1,y1,x2,y2) ->
    @ctx.moveTo(x1,y1)
    @ctx.lineTo(x2,y2)

  drawLink: (link, turtles, canWrapX, canWrapY) ->
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

      wrapX = shouldWrapInDim(canWrapX, @patchWidth,  e1x, e2x)
      wrapY = shouldWrapInDim(canWrapY, @patchHeight, e1y, e2y)

      if link.thickness is @onePixel
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

      @ctx.strokeStyle = netlogoColorToCSS(link.color)
      @ctx.lineWidth = if link.thickness > @onePixel then link.thickness else @onePixel
      @ctx.beginPath()

      if wrapX and wrapY
        # Unnecessary lines are drawn here since we're not checking to see which
        # are actually on screen. However, browsers are better at these checks
        # than we are and will ignore offscreen stuff. Thus, we shouldn't bother
        # checking unless we see a consistent performance improvement. Note that
        # at least 3 lines will be needed in the majority of cases and 4 lines
        # are necessary in certain cases. -- BCH (3/30/2014)
        if x1 < x2
          if y1 < y2
            @drawLine(x1, y1, x2 - @patchWidth, y2 - @patchHeight)
            @drawLine(x1 + @patchWidth, y1, x2, y2 - @patchHeight)
            @drawLine(x1 + @patchWidth, y1 + @patchHeight, x2, y2)
            @drawLine(x1, y1 + @patchHeight, x2 - @patchWidth, y2)
          else
            @drawLine(x1, y1, x2 - @patchWidth, y2 + @patchHeight)
            @drawLine(x1 + @patchWidth, y1, x2, y2 + @patchHeight)
            @drawLine(x1 + @patchWidth, y1 - @patchHeight, x2, y2)
            @drawLine(x1, y1 - @patchHeight, x2 - @patchWidth, y2)
        else
          if y1 < y2
            @drawLine(x1, y1, x2 + @patchWidth, y2 - @patchHeight)
            @drawLine(x1 - @patchWidth, y1, x2, y2 - @patchHeight)
            @drawLine(x1 - @patchWidth, y1 + @patchHeight, x2, y2)
            @drawLine(x1, y1 + @patchHeight, x2 + @patchWidth, y2)
          else
            @drawLine(x1, y1, x2 + @patchWidth, y2 + @patchHeight)
            @drawLine(x1 - @patchWidth, y1, x2, y2 + @patchHeight)
            @drawLine(x1 - @patchWidth, y1 - @patchHeight, x2, y2)
            @drawLine(x1, y1 - @patchHeight, x2 + @patchWidth, y2)
      else if wrapX
        if x1 < x2
          @drawLine(x1, y1, x2 - @patchWidth, y2)
          @drawLine(x1 + @patchWidth, y1, x2, y2)
        else
          @drawLine(x1, y1, x2 + @patchWidth, y2)
          @drawLine(x1 - @patchWidth, y1, x2, y2)
      else if wrapY
        if y1 < y2
          @drawLine(x1, y1, x2, y2 - @patchHeight)
          @drawLine(x1, y1 + @patchHeight, x2, y2)
        else
          @drawLine(x1, y1 - @patchHeight, x2, y2)
          @drawLine(x1, y1, x2, y2 + @patchHeight)
      else
        @drawLine(x1, y1, x2, y2)

    @ctx.stroke()

  repaint: (model) ->
    world = model.world
    turtles = model.turtles
    links = model.links
    @transformToWorld(world)
    if world.turtleshapelist != @drawer.shapes and typeof world.turtleshapelist == "object"
      @drawer = new CachingShapeDrawer(world.turtleshapelist)
    for id, link of links
      @drawLink(link, turtles, world.wrappingallowedinx, world.wrappingallowediny)
    @ctx.lineWidth = @onePixel
    for id, turtle of turtles
      @drawTurtle(turtle, world.wrappingallowedinx, world.wrappingallowediny)
    return

# Works by creating a scratchCanvas that has a pixel per patch. Those pixels
# are colored accordingly. Then, the scratchCanvas is drawn onto the main
# canvas scaled. This is very, very fast. It also prevents weird lines between
# patches.
# An alternative (and superior) method would be to make the main canvas have
# a pixel per patch and directly manipulate it. Then, use CSS to scale to the
# proper size. Unfortunately, CSS scaling introduces antialiasing, making the
# patches look blurred. An option to disable this antialiasing is coming in
# CSS4: image-rendering. Firefox currently supports it. Chrome did (with a
# nonstandard value), but no longer does.
# You can read about it here:
# https://developer.mozilla.org/en-US/docs/Web/CSS/image-rendering
class PatchView extends View
  constructor: (fontSize) ->
    super(fontSize)
    @scratchCanvas = document.createElement('canvas')
    @scratchCtx = @scratchCanvas.getContext('2d')
    @quality = 2 # Avoids antialiasing somewhat when image is stretched.

  transformToWorld: (world) ->
    super(world)
    @scratchCanvas.width = @patchWidth
    @scratchCanvas.height = @patchHeight
    # Prevents antialiasing when scratchCanvas is stretched and drawn on canvas
    @ctx.imageSmoothingEnabled=false
    # Althought imageSmoothingEnabled is in spec, I've seen it break from
    # version to version in browsers. These browser-specific flags seem to
    # work more reliably.
    @ctx.webkitImageSmoothingEnabled = false
    @ctx.mozImageSmoothingEnabled = false
    @ctx.oImageSmoothingEnabled = false
    @ctx.msImageSmoothingEnabled = false
    @ctx.fillStyle = 'black'
    @ctx.fillRect(@minpxcor - .5, @minpycor - .5, @patchWidth, @patchHeight)

  colorPatches: (patches) ->
    imageData = @ctx.createImageData(@patchWidth,@patchHeight)
    numPatches = ((@maxpycor-@minpycor)*@patchWidth + (@maxpxcor-@minpxcor)) * 4
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
    trans = @minpycor + @maxpycor
    @ctx.translate(0, trans)
    @ctx.scale(1,-1)
    @ctx.drawImage(@scratchCanvas, @minpxcor - .5, @minpycor - .5, @patchWidth, @patchHeight)
    @ctx.scale(1,-1)
    @ctx.translate(0, -trans)

  labelPatches: (patches) ->
    for ignore, patch of patches
      @drawLabel(patch.plabel, patch['plabel-color'], patch.pxcor + .5, patch.pycor - .5)

  clearPatches: ->
    @ctx.fillStyle = "black"
    @ctx.fillRect(@minpxcor - .5, @minpycor - .5, @patchWidth, @patchHeight)

  repaint: (model) ->
    world = model.world
    patches = model.patches
    if not @matchesWorld(world)
      @transformToWorld(world)
    if world.patchesallblack
      @clearPatches()
    else
      @colorPatches(patches)
    if world.patcheswithlabels
      @labelPatches(patches)

