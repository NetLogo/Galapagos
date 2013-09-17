if not window.AgentModel?
  console.error('view.js requires agentmodel.js!')

class window.AgentStreamController
  constructor: (@container) ->
    @turtleView = new TurtleView()
    @patchView = new PatchView()
    @layeredView = new LayeredView()
    @layeredView.setLayers(@patchView, @turtleView)
    @container.appendChild(@layeredView.canvas)
    @model = new AgentModel()
    @model.world.turtleshapelist = defaultShapes
    @repaint()

  repaint: ->
    @turtleView.repaint(@model.world, @model.turtles, @model.links)
    @patchView.repaint(@model.world, @model.patches)
    @layeredView.repaint()

  update: (modelUpdate) ->
    @model.update(modelUpdate)

class View
  constructor: () ->
    # Have size = 1 actually be patch-size pixels results in worse quality
    # for turtles. `quality` scales the number of pixels used. It should be as
    # small as possible as overly large canvases can crash computers
    @quality = 1
    @canvas = document.createElement('canvas')
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

class LayeredView extends View
  setLayers: (layers...) ->
    @layers = layers
  repaint: () ->
    @canvas.width = Math.max((l.canvas.width for l in @layers)...)
    @canvas.height = Math.max((l.canvas.height for l in @layers)...)
    # Note that scaling a high quality canvas to this canvas doesn't acutally
    # seem to degrade quality that much
    for layer in @layers
      @ctx.drawImage(layer.canvas, 0, 0, @canvas.width, @canvas.height)
    return

class TurtleView extends View
  constructor: () ->
    super()
    @drawer = new CachingShapeDrawer({})
    # Using quality = 1 here results in very pixelated turtles when using the
    # CachingShapeDrawer, something weird about the turtle image scaling.
    # Higher quality here seems preserved even when the LayeredView is
    # quality = 1.
    # quality = 3 was arrived at empirically. I noticed no improvement after 3.
    @quality = 3

  drawTurtle: (id, turtle) ->
    xcor = turtle.xcor or 0
    ycor = turtle.ycor or 0
    heading = turtle.heading or 0
    scale = turtle.size or 1
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

  drawLink: (link, turtles) ->
    end1 = turtles[link.end1]
    end2 = turtles[link.end2]

    @ctx.strokeStyle = netlogoColorToCSS(link.color)
    @ctx.lineWidth = if link.thickness > @onePixel then link.thickness else @onePixel
    @ctx.beginPath()
    @ctx.moveTo(end1.xcor, end1.ycor)
    @ctx.lineTo(end2.xcor, end2.ycor)
    @ctx.stroke()

  repaint: (world, turtles, links) ->
    @transformToWorld(world)
    if world.turtleshapelist != @drawer.shapes
      @drawer = new CachingShapeDrawer(world.turtleshapelist)
    for id, link of links
      @drawLink(link, turtles)
    @ctx.lineWidth = @onePixel
    for id, turtle of turtles
      @drawTurtle(id, turtle)
    return

class PatchView extends View
  constructor: () ->
    super()
    @patchColors = []

  transformToWorld: (world) ->
    super(world)
    @patchColors = []
    for x in [@minpxcor..@maxpxcor]
      for y in [@maxpycor..@minpycor]
        @colorPatch({'pxcor': x, 'pycor': y, 'pcolor': 'black'})
      col = 0
    return

  colorPatch: (patch) ->
    row = @maxpycor - patch.pycor
    col = patch.pxcor-@minpxcor
    patchIndex = row*@patchWidth + col
    color = patch.pcolor
    color = netlogoColorToCSS(color)
    if color != @patchColors[patchIndex]
      @patchColors[patchIndex] = @ctx.fillStyle = color
      @ctx.fillRect(patch.pxcor-.5, patch.pycor-.5, 1, 1)

  repaint: (world, patches) ->
    if not @matchesWorld(world)
      @transformToWorld(world)
    for _, p of patches
      @colorPatch(p)
