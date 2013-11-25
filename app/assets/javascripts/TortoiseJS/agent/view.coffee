if not window.AgentModel?
  console.error('view.js requires agentmodel.js!')

class window.AgentStreamController
  constructor: (@container) ->
    @layers = document.createElement('div');
    @layers.style.width = '100%'
    @layers.style.position = 'relative'
    @layers.classList.add('view-layers')
    @container.appendChild(@layers)
    @turtleView = new TurtleView()
    @patchView = new PatchView()
    # patchView must keep normal positioning so that it trying to maintain its
    # aspect ratio forces the container to stay tall enough, thus maintaining
    # flow with the rest of the page. Hence, we don't set its position
    # 'absolute'
    @turtleView.canvas.style.position = 'absolute'
    @turtleView.canvas.style.top = '0px'
    @turtleView.canvas.style.left = '0px'
    @layers.appendChild(@patchView.canvas)
    @layers.appendChild(@turtleView.canvas)
    @model = new AgentModel()
    @model.world.turtleshapelist = defaultShapes
    @repaint()

  repaint: ->
    @turtleView.repaint(@model.world, @model.turtles, @model.links)
    @patchView.repaint(@model.world, @model.patches)

  update: (modelUpdate) ->
    @model.update(modelUpdate)

class View
  constructor: () ->
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
    @ctx.font =  '10pt "Lucida Grande", sans-serif'

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
    @drawLabel(turtle.label, turtle['label-color'], xcor + turtle.size / 2, ycor - turtle.size / 2)

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
    if world.turtleshapelist != @drawer.shapes and typeof world.turtleshapelist == "object"
      @drawer = new CachingShapeDrawer(world.turtleshapelist)
    for id, link of links
      @drawLink(link, turtles)
    @ctx.lineWidth = @onePixel
    for id, turtle of turtles
      @drawTurtle(id, turtle)
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
  constructor: () ->
    super()
    @patchColors = []
    @scratchCanvas = document.createElement('canvas')
    @scratchCtx = @scratchCanvas.getContext('2d')
    @quality = 2 # Avoids antialiasing somewhat when image is stretched.

  transformToWorld: (world) ->
    super(world)
    @scratchCanvas.width = @patchWidth
    @scratchCanvas.height = @patchHeight
    # Prevents antialiasing when scratchCanvas is stretched and drawn on canvas
    @ctx.imageSmoothingEnabled=false;
    # Althought imageSmoothingEnabled is in spec, I've seen it break from
    # version to version in browsers. These browser-specific flags seem to
    # work more reliably.
    @ctx.webkitImageSmoothingEnabled = false;
    @ctx.mozImageSmoothingEnabled = false;
    @ctx.oImageSmoothingEnabled = false;
    @ctx.fillStyle = 'black'
    @ctx.fillRect(@minpxcor - .5, @minpycor - .5, @patchWidth, @patchHeight)

  colorPatches: (patches) ->
    imageData = @ctx.createImageData(@patchWidth,@patchHeight)
    for _, patch of patches
      [r,g,b] = netlogoColorToRGB(patch.pcolor)
      i = ((@maxpycor-patch.pycor)*@patchWidth + (patch.pxcor-@minpxcor)) * 4
      imageData.data[i+0] = r
      imageData.data[i+1] = g
      imageData.data[i+2] = b
      imageData.data[i+3] = 255
    @scratchCtx.putImageData(imageData, 0, 0)
    @ctx.scale(1,-1)
    @ctx.drawImage(@scratchCanvas, @minpxcor - .5, @minpycor - .5, @patchWidth, @patchHeight)
    @ctx.scale(1,-1)
    for _, patch of patches
      @drawLabel(patch.plabel, patch['plabel-color'], patch.pxcor + .5, patch.pycor - .5)

  repaint: (world, patches) ->
    if not @matchesWorld(world)
      @transformToWorld(world)
    @colorPatches(patches)
