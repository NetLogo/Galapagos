if not window.AgentModel?
  console.log('view.js requires agentmodel.js!')

class window.AgentStreamController
  constructor: (@container) ->
    @turtleView = new TurtleView()
    @patchView = new PatchView()
    @layeredView = new LayeredView()
    @layeredView.setLayers(@patchView, @turtleView)
    @container.appendChild(@layeredView.canvas)
    @model = new AgentModel()
    @repaint()

  repaint: ->
    @turtleView.repaint(@model.world, @model.turtles)
    @patchView.repaint(@model.world, @model.patches)
    @layeredView.repaint()

  update: (modelUpdate) ->
    if @model.update(modelUpdate)
      @repaint()

class View
  constructor: () ->
    @canvas = document.createElement('canvas')
    @canvas.width = 500
    @canvas.height = 500
    @canvas.style.width = "100%"
    @ctx = @canvas.getContext('2d')

  matchesWorld: (world) ->
    (@maxPxcor? and @minPxcor? and @maxPycor? and @minPycor? and @patchSize?) and
      (not world.maxPxcor? or world.maxPxcor == @maxPxcor) and
      (not world.minPxcor? or world.minPxcor == @minPxcor) and
      (not world.maxPycor? or world.maxPycor == @maxPycor) and
      (not world.minPycor? or world.minPycor == @minPycor) and
      (not world.patchSize? or world.patchSize == @patchSize)

  transformToWorld: (world) ->
    @maxPxcor = if world.maxPxcor? then world.maxPxcor else 25
    @minPxcor = if world.minPxcor? then world.minPxcor else -25
    @maxPycor = if world.maxPycor? then world.maxPycor else 25
    @minPycor = if world.minPycor? then world.minPycor else -25
    @patchSize = if world.patchSize? then world.patchSize else 9
    @patchWidth = @maxPxcor - @minPxcor + 1
    @patchHeight = @maxPycor - @minPycor + 1
    @canvas.width =  @patchWidth * @patchSize
    @canvas.height = @patchHeight * @patchSize
    # Argument rows are the matrix columns. See spec.
    @ctx.setTransform(@canvas.width/@patchWidth, 0,
                      0, -@canvas.height/@patchHeight,
                      -(@minPxcor-.5)*@canvas.width/@patchWidth,
                      (@maxPycor+.5)*@canvas.height/@patchHeight)

class LayeredView extends View
  setLayers: (layers...) ->
    @layers = layers
  repaint: () ->
    @canvas.width = Math.max((l.canvas.width for l in @layers)...)
    @canvas.height = Math.max((l.canvas.height for l in @layers)...)
    for layer in @layers
      @ctx.drawImage(layer.canvas, 0, 0)
    return

class TurtleView extends View
  drawTurtle: (id, turtle) ->
    xcor = turtle.xcor or 0
    ycor = turtle.ycor or 0
    heading = turtle.heading or 0
    scale = turtle.size or 1
    angle = (180-heading)/360 * 2*Math.PI
    shape = turtle.shape
    if typeof(shape)=='string'
      shape = shapes[shape] or shapes.default
    @ctx.save()
    @ctx.translate(xcor, ycor)
    if shape.rotate
      @ctx.rotate(angle)
    else
      @ctx.rotate(Math.PI)
    @ctx.scale(scale, scale)
    window.drawShape(@ctx, turtle.color, heading, shape)
    @ctx.restore()

  repaint: (world, turtles) ->
    @transformToWorld(world)
    @ctx.lineWidth = .1
    @ctx.fillStyle = 'red'
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
    for x in [@minPxcor..@maxPxcor]
      for y in [@maxPycor..@minPycor]
        @colorPatch({'pxcor': x, 'pycor': y, 'pcolor': 'black'})
      col = 0
    return

  colorPatch: (patch) ->
    row = patch.pxcor-@minPxcor
    col = @maxPycor - patch.pycor
    patchIndex = row*@patchWidth + col
    color = patch.pcolor
    if typeof(color) == 'number'
      color = netlogoColorToCSS(color)
    if color != @patchColors[patchIndex]
      @patchColors[patchIndex] = @ctx.fillStyle = color
      @ctx.fillRect(patch.pxcor-.5, patch.pycor-.5, 1, 1)

  repaint: (world, patches) ->
    if not @matchesWorld(world)
      @transformToWorld(world)
    for _, p of patches
      @colorPatch(p)
