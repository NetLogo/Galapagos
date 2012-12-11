@world =
  max_pxcor: 16
  min_pxcor: -16
  max_pycor: 16
  min_pycor: -16
  patch_size: 13

  make_square: (size) ->
    max=Math.ceil((size-1)/2)
    min=-Math.floor((size-1)/2)
    world.set_max_pxcor max
    world.set_min_pxcor min
    world.set_max_pycor max
    world.set_min_pycor min

  set_max_pxcor: (pcor) ->
    if world.max_pxcor!=pcor
      world.max_pxcor = pcor
      world.resize()
  set_min_pxcor: (pcor) ->
    if world.min_pxcor!=pcor
      world.min_pxcor = pcor
      world.resize()
  set_max_pycor: (pcor) ->
    if world.max_pycor!=pcor
      world.max_pycor = pcor
      world.resize()
  set_min_pycor: (pcor) ->
    if world.min_pycor!=pcor
      world.min_pycor = pcor
      world.resize()

  set_patch_size: (pixels) ->
    if world.patch_size!=pixels
      world.patch_size = pixels
      world.resize()

  clear_all: ->
    world.clear_patches()
    world.clear_drawing()
    world.clear_turtles()

  clear_drawing: ->

  clear_patches: ->
    window.patches = []
    window.patches_by_cors = {}
    for pxcor in [world.min_pxcor..world.max_pxcor]
      for pycor in [world.min_pycor..world.max_pycor]
        newPatch = new Patch(pxcor, pycor)
        patches.push newPatch

  clear_turtles: ->
    window.turtles = []

  max_xcor: -> world.max_pxcor + .5
  min_xcor: -> world.min_pxcor - .5
  max_ycor: -> world.max_pycor + .5
  min_ycor: -> world.min_pycor - .5
  world_width: -> world.max_pxcor - world.min_pxcor + 1
  world_height: -> world.max_pycor - world.min_pycor + 1


world.ca = world.clear_all
world.cd = world.clear_drawing
world.cp = world.clear_patches
world.ct = world.clear_turtles


Number::mod = (n) -> ((this%n)+n)%n
@wrap = (x, min, max) -> (x-min).mod(max-min)+min

# deltaX(x1,x2) is the number closest to zero such that:
# wrap(x2+deltaX(x1,x2), world.min_xcor(), world.max_xcor()) == x1
@deltaX = (x1, x2) ->
  width = world.world_width()
  dx = x1-x2
  if Math.abs(dx)>width/2
    if dx>0
      return dx-width
    else
      return width+dx
  return dx

# deltaY(y1,y2) is the number closest to zero such that:
# wrap(y2+deltaY(y1,y2), world.min_pycor, world.max_pycor) == y1
@deltaY = (y1, y2) ->
  height = world.world_height()
  dy = y1-y2
  if Math.abs(dy)>height/2
    if dy>0
      return dy-height
    else
      return height+dy
  return dy

@dist_squared = (x1,y1,x2,y2) ->
  dx = deltaX(x1,x2)
  dy = deltaY(y1,y2)
  dx*dx+dy*dy

@dist = (x1,y1,x2,y2) -> Math.sqrt dist_squared x1, y1, x2, y2

@subtract_headings = (h1, h2) ->
  dh = (h1 - h2).mod(360)
  if dh>180
    return dh-360
  else
    return dh

@sin = (degrees) -> Math.sin(2*Math.PI*degrees/360)
@cos = (degrees) -> Math.cos(2*Math.PI*degrees/360)
@tan = (degrees) -> Math.tan(2*Math.PI*degrees/360)
@atan = (x,y) -> 360*Math.atan2(x,y)/(Math.PI*2)

@sum = (xs) ->
  total = 0
  for x in xs
    total+=x
  return total
@mean = (xs) -> sum(xs)/xs.length

@random_float = Math.random
@random = (n) -> Math.floor(random_float()*n)
@random_xcor = -> random_float()*world.world_width() + world.min_xcor()
@random_ycor = -> random_float()*world.world_height() + world.min_ycor()

@turtles = []
class Turtle
  xcor: 0
  ycor: 0
  heading: 0
  size: 1
  color: "red"
  pen_mode: "up"
  _needRender: true
  _prerenderCanvas: null

  constructor: ->
    @set_color "hsl("+random(360)+",100%,50%)"
    @heading = random 360
    @_prerenderCanvas = document.createElement("canvas")
  dx: => sin(@heading)
  dy: => cos(@heading)
  setxy: (x,y) ->
    @xcor = wrap(x, world.min_xcor(), world.max_xcor())
    @ycor = wrap(y, world.min_ycor(), world.max_ycor())
    return
  set_color: (color) -> @color = color; @_needRender = true
  set_size: (size) -> @size = size; @_needRender = true
  left: (rad) -> @heading-=rad
  right: (rad) -> @heading+=rad
  forward: (dist) -> @setxy(@xcor+@dx()*dist,@ycor+@dy()*dist)
  distancexy: (x, y) -> dist(@xcor, @ycor, x, y)
  distance: (other) -> @distancexy(other.xcor, other.ycor)
  in_radius: (r,other) -> dist_squared(@xcor, @ycor, other.xcor, other.ycor)<r*r
  towardsxy: (x, y) -> atan deltaX(x, @xcor), deltaY(y, @ycor)
  towards: (other) -> @towardsxy(other.xcor, other.ycor)
  patch_here: -> patch @xcor, @ycor
  pen_down: -> @pen_mode = "down"
  pen_up: -> @pen_mode = "up"
  hatch: (n, commands) ->
    # FIXME: This will have problems, especially when breeds are introduced.
    for i in [1..n]
      baby = new Turtle()
      for key, value of this
        # skip functions and private attributes
        if typeof baby[key] != "function" and key[0]!='_'
          baby[key] = value
      if commands?
        commands.call baby
      turtles.push baby
    return
  die: -> window.turtles = (t for t in turtles when t isnt this)
  stamp: -> @drawToCtx penCtx
  draw: -> @drawToCtx turtleCtx
  drawToCtx: (targetCtx)->
    image = @_prerenderCanvas
    if @_needRender
      image.width = @size*world.patch_size
      image.height = image.width
      ctx = image.getContext("2d")
      @_needRender = false
      @_renderToContext(ctx)
    px = xPatchToPix @xcor
    py = yPatchToPix @ycor
    theta = @heading/360*(Math.PI*2)
    targetCtx.translate px, py
    targetCtx.rotate theta
    targetCtx.drawImage image, -image.width/2, -image.height/2
    targetCtx.rotate -theta
    targetCtx.translate -px, -py

  _renderToContext: (ctx) ->
    # On it's own coordinate system, the turtle should be centered on 0,0
    # pointing straight up
    image = @_prerenderCanvas
    ctx.clearRect 0, 0, image.width, image.height
    r = @size/2
    trans = (x) -> transCor x, -r, r, 0, image.width
    x = y = 0
    h = 180
    ctx.fillStyle = @color
    ctx.beginPath()
    ctx.moveTo trans(x+r*sin(h)), trans(y+r*cos(h))
    ctx.lineTo trans(x+r*sin(h+130)), trans(y+r*cos(h+130))
    ctx.lineTo trans(x+r/3*sin(h+180)), trans(y+r/3*cos(h+180))
    ctx.lineTo trans(x+r*sin(h-130)), trans(y+r*cos(h-130))
    ctx.closePath()
    ctx.fill()

Turtle::lt = Turtle::left
Turtle::rt = Turtle::right
Turtle::fd = Turtle::forward
Turtle::pd = Turtle::pen_down
Turtle::pu = Turtle::pen_up

@patches
class Patch
  pcolor:  "black"
  set_pcolor: (newColor) ->
    if newColor!=@pcolor
      @pcolor = newColor
      @draw()
  constructor: (@pxcor, @pycor) ->
  draw: ->
    patchCtx.fillStyle = @pcolor
    lPixX = xPatchToPix(@pxcor - .5)
    tPixY = yPatchToPix(@pycor + .5)
    s = world.patch_size
    patchCtx.fillRect lPixX, tPixY, s, s


@patch_no_wrap = (x, y) ->
  rows = world.max_pycor-world.min_pycor+1
  row = Math.round(y-world.min_pycor)
  col = Math.round(x-world.min_pxcor)
  patches[rows*col + row]

@patch = (x, y) ->
  rows = world.max_pycor-world.min_pycor+1
  cols = world.max_pxcor-world.min_pxcor+1
  row = Math.round(y-world.min_pycor).mod(rows)
  col = Math.round(x-world.min_pxcor).mod(cols)
  patches[rows*col + row]

@create_turtles = (n, initTurtle = null) ->
  newTurtles = (new Turtle for i in [1..n])
  if initTurtle?
    ask newTurtles, initTurtle
  window.turtles = window.turtles.concat newTurtles

@crt = @create_turtles

@ask = (agents, method) ->
  if agents.items?
    agents = agents.items
  method.call(a) for a in agents

@min_one_of = (agents, key) ->
  if agents.length==0
    return null
  minAgent = agents[0]
  minVal = key(minAgent)
  for agent in agents
    val = key(agent)
    if minVal>val
      minVal = val
      minAgent = agent
  minAgent
