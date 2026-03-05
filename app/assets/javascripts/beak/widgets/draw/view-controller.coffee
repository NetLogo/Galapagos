import defaultShapes from "/default-shapes.js"
import { CompositeLayer } from "./composite-layer.js"
import { TurtleLayer } from "./turtle-layer.js"
import { PatchLayer } from "./patch-layer.js"
import { DrawingLayer } from "./drawing-layer.js"
import { SpotlightLayer } from "./spotlight-layer.js"
import { HighlightLayer } from "./highlight-layer.js"
import { setImageSmoothing, clearCtx, extractWorldShape } from "./draw-utils.js"

AgentModel = tortoise_require('agentmodel')

# TODO type signature
initLayers = (layerDeps) ->
  # Tis important that we don't access the properties of `layerDeps` except within the client code using `layerDeps`,
  # because the identities of the objects will change (see "./layers.coffee"'s comment on layer dependencies' for why).
  turtles = new TurtleLayer(-> layerDeps)
  patches = new PatchLayer(-> layerDeps)
  drawing = new DrawingLayer(-> layerDeps)
  world = new CompositeLayer([patches, drawing, turtles], -> layerDeps)
  spotlight = new SpotlightLayer(-> layerDeps)
  highlight = new HighlightLayer(-> layerDeps)
  all = new CompositeLayer([world, spotlight, highlight], -> layerDeps)
  { turtles, patches, drawing, world, spotlight, highlight, all }

class ViewController
  # (Unit) -> Unit
  constructor: ->
    # Define `@_layerDeps` first because the `@resetModel()` call below needs this variable to be valid.
    @_layerDeps = {
      model: {
        model: undefined # will be set by `@resetModel`
        worldShape: undefined # will be set by `@resetModel`
      },
      highlight: {
        highlightedAgents: []
      },
      quality: { quality: Math.max(window.devicePixelRatio ? 2, 2) },
      font: {
        fontFamily: '"Lucida Grande", sans-serif',
        fontSize: 50 # some random number; can be set by the client
      }
    }
    @resetModel() # defines `@_model`
    @_layers = initLayers(@_layerDeps)

    repaint = => @repaint()
    drawingLayer = @_layers.drawing
    allLayer = @_layers.all
    @configShims = {
      importImage: (b64, x, y) -> drawingLayer.importImage(b64, x, y).then(repaint),
      getViewBase64: -> allLayer.getCanvas().toDataURL("image/png"),
      getViewBlob: (callback) -> allLayer.getCanvas().toBlob(callback, "image/png")
    }

    @_views = [] # Stores the views themselves; some values might be null for destructed views

    # Array[{ downHandler: MouseHandler, moveHandler: MouseHandler, upHandler: MouseHandler }]
    @_mouseListeners = []
    # Tracks the latest known information about the location of the mouse.
    # `currentlyInteracting` denotes whether the start handler has been fired without the corresponding end handler
    # having been fired yet. If `currentlyInteracting` is true, `view` must not also be undefined.
    @_latestMouseInfo = { currentlyInteracting: false, view: undefined, clientX: 0, clientY: 0, xPcor: 0, yPcor: 0 }

    @repaint()
    return

  # (MouseHandler, MouseHandler, MouseHandler) -> (Unit) -> Unit
  # where MouseHandler: ({
  #   event: MouseEvent? | TouchEvent?,
  #   view: View,
  #   clientX: number,
  #   clientY: number,
  #   xPcor: number?,
  #   yPcor: number?,
  # }) -> Unit
  # Registering another set of mouse listeners while the previously active set of listeners was "still interacting"
  # (as in the down handler was fired but not the up handler) causes the previous end listener to fire and the new
  # down handler to fire, as if the mouse interaction immediately ended and then began again. Returns an unsubscribe
  # function that removes the listeners. This unsubscribe function does not call the up handler even if the down handler
  # was called.
  registerMouseListeners: (downHandler, moveHandler, upHandler) ->
    if @_latestMouseInfo.currentlyInteracting
      { view, clientX, clientY, xPcor, yPcor } = @_latestMouseInfo
      @_mouseListeners[0]?.upHandler({ view, clientX, clientY, xPcor, yPcor })
      downHandler({ view, clientX, clientY, xPcor, yPcor })
    handlerObj = { downHandler, moveHandler, upHandler }
    @_mouseListeners.unshift(handlerObj)
    =>
      index = @_mouseListeners.indexOf(handlerObj)
      if index >= 0 then @_mouseListeners.splice(index, 1)
      if index is 0 then @_latestMouseInfo.currentlyInteracting = false

  # (Unit) -> Unit
  resetModel: ->
    @_model = new AgentModel()
    @_model.world.turtleshapelist = defaultShapes
    @_layerDeps.model = {
      @_layerDeps.model...,
      model: @_model,
      worldShape: extractWorldShape(@_model.world)
    }
    return

  # (Unit) -> AgentModel
  getModel: => @_model

  # (Unit) -> WorldShaspe
  getWorldShape: => @_layerDeps.model.worldShape

  # (Unit) -> Unit
  repaint: ->
    for view in @_views when view?
      view.repaint()
    return

  # (Dims) => Unit
  setTargetDims: (@_targetDims) ->
    @repaint()
    return

  # (Update|Array[Update]) => Unit
  _applyUpdateToModel: (modelUpdate) ->
    updates = if Array.isArray(modelUpdate) then modelUpdate else [modelUpdate]
    @_model.update(u) for u in updates
    return

  # (Update|Array[Update]) => Unit
  update: (modelUpdate) ->
    @_applyUpdateToModel(modelUpdate)
    @_layerDeps.model = {
      @_layerDeps.model...,
      worldShape: extractWorldShape(@_model.world)
    }
    @repaint()
    @_model.drawingEvents = []
    return

  # (number) -> Unit
  setQuality: (quality) ->
    # It's important that we create a new object instead of setting the property on the old object.
    @_layerDeps.quality = { quality }
    @repaint()
    return

  # (Array[Agent]) -> Unit
  # where `Agent` is the actual agent object as opposed to the `AgentModel` analogue
  setHighlightedAgents: (highlightedAgents) ->
    # It's important that we create a new object instead of simply setting the property on the old `@_layerDeps.model`
    # object.
    @_layerDeps.highlight = { @_layerDeps.highlight..., highlightedAgents }
    @repaint()
    return

  # We have the `avoidRepaint` parameter because the view widget sets the font size while rendering, but the world is
  # not ready to render yet. I'd like to see a way to eliminate this mess.
  # (string?, number?, boolean) -> Unit
  setFont: (fontFamily, fontSize, avoidRepaint = false) ->
    fontFamily or= @_layerDeps.font.fontFamily
    fontSize or= @_layerDeps.font.fontSize
    # It's important that we create a new object instead of setting the properties on the old one.
    @_layerDeps.font = { fontFamily, fontSize }
    if not avoidRepaint then @repaint()
    return

  # Returns a new WindowView that controls the specified container
  # The returned View must be destructed before it is dropped.
  # (Node, string, Iterator<Rectangle>) -> WindowView
  getNewView: (container, layerName, windowRectGen) ->
    layer = @_layers[layerName]
    updateLatestMouseInfo = (mouseHandlerArg) =>
      {
        view: @_latestMouseInfo.view,
        clientX: @_latestMouseInfo.clientX,
        clientY: @_latestMouseInfo.clientY,
        xPcor: @_latestMouseInfo.xPcor,
        yPcor: @_latestMouseInfo.yPcor
      } = mouseHandlerArg
    mouseHandlers = {
      downHandler: (arg) =>
        updateLatestMouseInfo(arg)
        @_latestMouseInfo.currentlyInteracting = true
        @_mouseListeners[0]?.downHandler(arg)
      moveHandler: (arg) =>
        updateLatestMouseInfo(arg)
        @_mouseListeners[0]?.moveHandler(arg)
      upHandler: (arg) =>
        updateLatestMouseInfo(arg)
        @_latestMouseInfo.currentlyInteracting = false
        @_mouseListeners[0]?.upHandler(arg)
    }
    @_registerView((unregisterThisView) ->
      new View(container, layer, mouseHandlers, windowRectGen, unregisterThisView)
    )

  # Using the passed in `createView` function, creates and registers a new View to this
  # ViewController, then returns that view. The `createView` function should handle everything
  # involved with creating the view, except for the View's unregister function, which it takes as
  # a parameter (because it's only during the registration process that the unregister function
  # can be determined).
  # (((Unit) -> Unit) -> View) -> View
  _registerView: (createView) ->
    # find the first unused index to put this view
    index = @_views.findIndex((element) -> not element?)
    if index is -1 then index = @_views.length
    # Create a new scope so that variables are protected in case someone decides to create
    # like-named variables in a higher scope, thus causing CoffeeScript to destroy this scope.
    # CoffeeScript issues ;-; --Andre C.
    return do (index) =>
      unregisterThisView = =>
        @_views[index] = null
      view = createView(unregisterThisView)
      @_views[index] = view
      return view

# Each view into the NetLogo universe.
# Takes an iterator that returns Rectangles (see "./window-generators.coffee" for type info) to determine which part of
# the universe to observe, as well as the size of the canvas.
class View
  # (Node, Layer, MouseHandlers, Iterator<Rectangle>, (Unit) -> Unit) -> Unit
  # where MouseHandlers: { downHandler: MouseHandler, moveHandler: MouseHandler, upHandler: MouseHandler }
  # where MouseHandler is as described in the comment on `ViewController`
  constructor: (@_container, @_sourceLayer, @_mouseHandlers, @_windowRectGen, @_unregisterThisView) ->
    # Track the dimensions of the window rectangle currently being displayed so that we know when the canvas
    # dimensions need to be updated.
    @_windowCornerX = undefined
    @_windowCornerY = undefined
    @_windowWidth = undefined
    @_windowHeight = undefined

    @_quality = 1

    @_latestWorldShape = undefined # tracked so that the `pixToPcor` methods can handle wrapping

    # N.B.: since the canvas's dimensions might often change, the canvas is always kept at its
    # default drawing state (no transformations, no fillStyle, etc.) except temporarily when it is
    # actively being drawn to.
    @_visibleCanvas = document.createElement('canvas')
    @_visibleCanvas.classList.add('netlogo-canvas', 'unselectable')
    @_visibleCtx = @_visibleCanvas.getContext('2d')
    setImageSmoothing(@_visibleCtx, false)
    @_container.appendChild(@_visibleCanvas)

    @_initMouseTracking()
    @_initTouchTracking()
    return

  # (Unit) -> DOMRect
  getBoundingClientRect: -> @_visibleCanvas.getBoundingClientRect()

  # Note: For proper mouse and touch tracking, the <canvas> element must have no padding or border. This is because the
  # `offsetX` and `offsetY` properties plus the client bounding box, used in the mouse-tracking functions, account for
  # padding and/or border, which we do not want.

  # Unit -> Unit
  _initMouseTracking: ->
    createMouseHandlerArg = (e) => {
      event: e,
      view: this,
      clientX: e.clientX,
      clientY: e.clientY,
      xPcor: @xPixToPcor(e.offsetX),
      yPcor: @yPixToPcor(e.offsetY)
    }

    mouseIsDown = false # Records whether the mouse was pressed down *while inside the view*; so dragging a cursor that
    # is already held down doesn't trigger either the down handlers or up handlers.
    @_visibleCanvas.addEventListener('mousedown', (e) =>
      @_mouseHandlers.downHandler(createMouseHandlerArg(e))
      mouseIsDown = true
      return
    )
    @_visibleCanvas.addEventListener('mouseup', (e) =>
      if mouseIsDown
        @_mouseHandlers.upHandler(createMouseHandlerArg(e))
        mouseIsDown = false
      return
    )
    @_visibleCanvas.addEventListener('mousemove', (e) => @_mouseHandlers.moveHandler(createMouseHandlerArg(e)))
    @_visibleCanvas.addEventListener('mouseleave', (e) =>
      if mouseIsDown
        @_mouseHandlers.upHandler(createMouseHandlerArg(e))
        mouseIsDown = false
      return
    )
    return

  # Unit -> Unit
  _initTouchTracking: ->
    # Returns a valid argument for a MouseHandler, as well as a boolean for whether the touch is inside the canvas
    # element.
    createMouseHandlerArg = (e) =>
      { left, top, right, bottom } = @_visibleCanvas.getBoundingClientRect()
      { clientX, clientY } = e.changedTouches[0]
      [
        { event: e, view: this, clientX, clientY,
          xPcor: @xPixToPcor(clientX - left), yPcor: @yPixToPcor(clientY - top) },
        (left <= clientX <= right) and (top <= clientY <= bottom)
      ]

    movedOutside = false
    endTouch = (e) =>
      if movedOutside then return # ignore event if the current touch already moved out of the canvas
      [mouseHandlerArg, inside] = createMouseHandlerArg(e)
      if inside
        @_mouseHandlers.upHandler(mouseHandlerArg)
      return
    @_visibleCanvas.addEventListener('touchend', endTouch)
    @_visibleCanvas.addEventListener('touchcancel', endTouch)
    @_visibleCanvas.addEventListener('touchmove', (e) =>
      e.preventDefault()
      if movedOutside then return # ignore event if the current touch already moved out of the canvas
      [mouseHandlerArg, inside] = createMouseHandlerArg(e)
      if inside
        @_mouseHandlers.moveHandler(mouseHandlerArg)
      else
        # The current touch has moved out of the canvas, so ignore this and have future touchmove events be ignored too
        # Also fire the up handler
        movedOutside = true
        @_mouseHandlers.upHandler(mouseHandlerArg)
      return
    )
    @_visibleCanvas.addEventListener('touchstart', (e) =>
      [mouseHandlerArg, inside] = createMouseHandlerArg(e)
      # Since touches have size, and aren't just infinitesimal points, this event might falsely fire if the touch
      # happens to ontact the canvas even if the center of the touch isn't in the canvas.
      if not inside then return

      movedOutside = false # Have future touchmove events *not* be ignored.
      @_mouseHandlers.downHandler(mouseHandlerArg)
      return
    )
    return

  # (number) -> Unit
  setQuality: (@_quality) ->

  # Repaints the visible canvas, updating its dimensions. Overriding methods should call `super()`.
  # (Unit) -> Unit
  repaint: ->
    # Just because the source layer didn't change since the last time *it* was repainted, doesn't mean that it hasn't
    # changed since the last time *this view* was repainted, so don't short circuit even if `repaint` returns false.
    @_sourceLayer.repaint()
    @_latestWorldShape = @_sourceLayer.getWorldShape()
    @_updateDimensionsAndClear(@_windowRectGen.next().value)
    @_sourceLayer.drawRectTo(@_visibleCtx, @_windowCornerX, @_windowCornerY, @_windowWidth, @_windowHeight)
    return

  # Updates this view's canvas dimensions, as well as the `_windowWidth` and `_windowHeight` properties to match the
  # aspect ratio of the specified Rectangle, and clears the visible canvas.
  # (Rectangle) -> { x: number, y: number, w: number, h: number }
  # See "./window-generators.coffee" for type info on "Rectangle"
  _updateDimensionsAndClear: ({ x: @_windowCornerX, y: @_windowCornerY, w, h, canvasHeight }) ->
    # See if the height has changed.
    if not h? or (h is @_windowHeight and w is @_windowWidth)
      # The new rectangle has the same dimensions as the old.
      @_setCanvasDimensionsAndClear(canvasHeight, false)
      return

    # Now we know the rectangle must specify a new height.
    @_windowHeight = h

    # See if the width has changed.
    if not w? or w is @_windowWidth
      # If the rectangle did not specify a new width, we should calculate the width ourselves
      # to maintain the aspect ratio. We use the canvas dimensions to calculate the aspect ratio since
      # they haven't changed from the last frame, whereas `@_windowHeight` has.
      @_windowWidth = w ? (h * @_visibleCanvas.width / @_visibleCanvas.height)
      @_setCanvasDimensionsAndClear(canvasHeight, false)
      return

    # Now we know the rectangle must specify a new width and the aspect ratio might change.
    @_windowWidth = w
    @_setCanvasDimensionsAndClear(canvasHeight, true)
    return

  # Ensures that the canvas is properly sized to have the specified height while maintaining the aspect ratio specified
  # by `@_windowWidth` and @_windowHeight`. `canvasHeight` can be optional, in which case it will keep the same height
  # and maintain aspect ratio.
  _setCanvasDimensionsAndClear: (canvasHeight, changedAspRatio) ->
    if canvasHeight? and canvasHeight * @_quality isnt @_visibleCanvas.height
      # The canvas height must change.
      @_visibleCanvas.height = canvasHeight * @_quality
      @_visibleCanvas.width = @_visibleCanvas.height * @_windowWidth / @_windowHeight
      @_visibleCanvas.style.height = "#{canvasHeight}px"
      @_visibleCanvas.style.width = "#{@_visibleCanvas.width / @_quality}px"
    else if changedAspRatio
      # The canvas height did not change but the aspect ratio did.
      @_visibleCanvas.width = @_visibleCanvas.height * @_windowWidth / @_windowHeight
      @_visibleCanvas.style.width = "#{@_visibleCanvas.width / @_quality}px"
    else
      # Neither the canvas height not the aspect ratio changed; just clear the canvas and be done with it.
      clearCtx(@_visibleCtx)

  # These convert between model coordinates and position in the canvas DOM element
  # This will differ from untransformed canvas position if quality != 1. BCH 5/6/2015
  # Return null if the point lies outside the moudel coordinates.
  # (number) -> number?
  xPixToPcor: (xPix) ->
    { actualMinX, actualMaxX, worldWidth, wrapX } = @_latestWorldShape
    # Calculate the patch coordinate by extrapolating from the window dimensions and the point's
    # relative position to the window, ignoring possible wrapping.
    rawPcor = @_windowCornerX + xPix / @_visibleCanvas.clientWidth * @_windowWidth
    if wrapX
      # Account for wrapping in the world.
      (rawPcor - actualMinX) %% worldWidth + actualMinX
    else if actualMinX <= rawPcor and rawPcor <= actualMaxX
      rawPcor
    else
      undefined
  yPixToPcor: (yPix) ->
    { actualMinY, actualMaxY, worldHeight, wrapY } = @_latestWorldShape
    # Calculate the patch coordinate by extrapolating from the window dimensions and the point's
    # relative position to the window, ignoring possible wrapping.
    rawPcor = @_windowCornerY - yPix / @_visibleCanvas.clientHeight * @_windowHeight
    if wrapY
      # Account for wrapping in the world
      (rawPcor - actualMinY) %% worldHeight + actualMinY
    else if actualMinY <= rawPcor and rawPcor <= actualMaxY
      rawPcor
    else
      undefined

  # (Unit) -> Unit
  destructor: ->
    @_container.replaceChildren()
    @_unregisterThisView()
    return

export default ViewController
