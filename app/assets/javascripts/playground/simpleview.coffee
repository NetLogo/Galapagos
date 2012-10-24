if not window.AgentModel?
  console.log('simpleview.js requires agentmodel.js!')

class window.AgentStreamController
  constructor: (@container) ->
    @turtleView = new TurtleView()
    @patchView = new PatchView()
    @layeredView = new LayeredView()
    @layeredView.setLayers(@patchView, @turtleView)
    @layeredView.setContainer(@container)
    @model = new AgentModel()
    @repaint()

  repaint: -> 
    console.log 'Repainting turtle view'
    @turtleView.repaint(@model.world, @model.turtles)
    console.log 'Repainting patch view'
    @patchView.repaint(@model.world, @model.patches)
    console.log 'Repainting layered view'
    @layeredView.repaint()

  update: (modelUpdate) ->
    @model.update(modelUpdate)
    @repaint()

class View
  constructor: () ->
    @canvas = document.createElement('canvas')
    @canvas.width = 500
    @canvas.height = 500
    @ctx = @canvas.getContext('2d')

  setContainer: (container) -> container.appendChild(@canvas)

  matchesWorld: (world) ->
    (not world.maxPxcor? or world.maxPxcor == @maxPxcor)
    and (not world.minPxcor? or world.minPxcor == @minPxcor)
    and (not world.maxPycor? or world.maxPycor == @maxPycor)
    and (not world.minPycor? or world.minPycor == @minPycor)
    and (not world.patchSize? or world.patchSize == @patchSize)

  transformToWorld: (world) ->
    @maxPxcor = if world.maxPxcor? then world.maxPxcor else 16
    @minPxcor = if world.minPxcor? then world.minPxcor else -16
    @maxPycor = if world.maxPycor? then world.maxPycor else 16
    @minPycor = if world.minPycor? then world.minPycor else -16
    @patchSize = if world.patchSize? then world.patchSize else 13
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
    console.log 'hi'
    console.log layers
    @layers = layers

  repaint: () ->
    for layer in @layers
      console.log 'drawing #{layer}'
      @ctx.drawImage(layer.canvas, 0, 0)


class TurtleView extends View
  drawTurtle: (turtle) ->
    xcor = turtle.xcor or 0
    ycor = turtle.ycor or 0
    heading = turtle.heading or 0
    angle = (90-heading)/360 * 2*Math.PI
    @ctx.save()
    @ctx.translate(xcor, ycor)
    @ctx.rotate(angle)
    @ctx.beginPath()
    @ctx.moveTo(.5, 0)
    @ctx.lineTo(-.5, -.5)
    @ctx.lineTo(-.5, .5)
    @ctx.closePath()
    @ctx.fill()
    @ctx.restore()

  repaint: (world, turtles) ->
    @transformToWorld(world)
    @ctx.lineWidth = .1
    @ctx.fillStyle = 'red'
    for _, turtle of turtles
      @drawTurtle(turtle)
    return

class PatchView extends View
  constructor: () -> @patchColors = []

  colorPatch: (patch) ->

  repaint: (world, patches) ->
    if not @matchesWorld(world)
      @transformToWorld(world)
    @ctx.fillStyle = 'black'
    @ctx.fillRect(@minPxcor, @minPycor, @patchWidth, @patchHeight)

