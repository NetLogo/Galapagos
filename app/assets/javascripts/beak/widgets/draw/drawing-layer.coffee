import { mergeInfo, Layer } from "./layer.js"
import { drawTurtle } from "./draw-shape.js"
import { drawLink } from "./link-drawer.js"
import { resizeCanvas, usePatchCoords, useCompositing, useImageSmoothing } from "./draw-utils.js"

rgbToCss = ([r, g, b]) -> "rgb(#{r}, #{g}, #{b})"

compositingOperation = (mode) ->
  if mode is 'erase' then 'destination-out' else 'source-over'

makeMockTurtleObject = ({ x: xcor, y: ycor, shapeName: shape, size, heading, color }) ->
  { xcor, ycor, shape, size, heading, color }

makeMockLinkObject = ({ x1, y1, x2, y2, shapeName, color, heading, size, 'directed?': isDirected
                      , 'hidden?': isHidden, midpointX, midpointY, thickness }) ->
  end1 = { xcor: x1, ycor: y1 }
  end2 = { xcor: x2, ycor: y2 }

  mockLink = { shape: shapeName, color, heading, size, 'directed?': isDirected
                , 'hidden?': isHidden, midpointX, midpointY, thickness }

  [mockLink, end1, end2]

###
type DrawingEvent = { type: "clear-drawing" | "line" | "stamp-image" | "import-drawing" }

Possible drawing events:
{ type: "clear-drawing" }
{ type: "line", fromX, fromY, toX, toY, rgb, size, penMode }
{ type: "stamp-image", agentType: "turtle", stamp: {x, y, size, heading, color, shapeName, stampMode} }
{ type: "stamp-image", agentType: "link", stamp: {
    x1, y1, x2, y2, midpointX, midpointY, heading, color, shapeName, thickness, 'directed?', size, 'hidden?', stampMode
  }
}
{ type: "import-drawing", imageBase64 }
###

class DrawingLayer extends Layer
  # (-> { model: ModelObj, quality: QualityObj, font: FontObj }, (Unit) -> Unit) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_getDepInfo, @_repaintCallback = ->) ->
    super()
    @_latestDepInfo = {
      model: undefined,
      quality: undefined,
      font: undefined
    }
    @_dirty = false
    # Tracks whether anything is currently drawn to `@_canvas` (since the last `clear-drawing`).  At the moment this is
    # only used to snapshot the layer for HubNet Web clients that join after the drawing was created.
    # -Jeremy B June 2026
    @_hasContent = false
    @_canvas = document.createElement('canvas')
    @_ctx = @_canvas.getContext('2d')
    return

  getWorldShape: -> @_latestDepInfo.model.worldShape

  # () => Boolean
  hasContent: -> @_hasContent

  # () => String - a `data:` URL PNG snapshot of the current drawing layer
  getSnapshotURL: -> @_canvas.toDataURL("image/png")

  blindlyDrawTo: (ctx) ->
    ctx.drawImage(@_canvas, 0, 0)
    return

  repaint: ->
    depsChanged = mergeInfo(@_latestDepInfo, @_getDepInfo())
    wasDrawnAsync = @_dirty
    @_dirty = false
    if not depsChanged and not wasDrawnAsync then return false

    if depsChanged
      { model: { model, worldShape }, quality: { quality } } = @_latestDepInfo
      { worldWidth, worldHeight, patchsize } = worldShape
      # Round to whole pixels: canvas dimensions are always integers, so comparing against a
      # fractional target (possible when `quality`/devicePixelRatio is fractional) would report a
      # size change on every repaint, re-running the copy-and-rescale below and progressively
      # blurring the drawing. -JB July 2026
      newWidth  = Math.round(worldWidth  * patchsize * quality)
      newHeight = Math.round(worldHeight * patchsize * quality)
      if @_canvas.width isnt newWidth or @_canvas.height isnt newHeight
        # Save drawing content before resize (setting canvas dimensions always clears the canvas)
        prevCanvas = document.createElement('canvas')
        prevCanvas.width  = @_canvas.width
        prevCanvas.height = @_canvas.height
        prevCanvas.getContext('2d').drawImage(@_canvas, 0, 0)
        @_canvas.width  = newWidth
        @_canvas.height = newHeight
        if prevCanvas.width > 0 and prevCanvas.height > 0
          @_ctx.drawImage(prevCanvas, 0, 0, newWidth, newHeight)
      for event in model.drawingEvents
        switch event.type
          when 'clear-drawing' then @_clearDrawing()
          when 'line' then @_drawLine(event)
          when 'stamp-image'
            switch event.agentType
              when 'turtle' then @_drawTurtleStamp(event.stamp)
              when 'link' then @_drawLinkStamp(event.stamp)
          when 'import-drawing' then @_importDrawing(event.imageBase64)
      # For those who still remember, `model.drawingEvents` is now reset by the ViewController after
      # every layer has finished repainting.

    true

  _clearDrawing: ->
    @_ctx.clearRect(0, 0, @_canvas.width, @_canvas.height)
    @_hasContent = false
    return

  _drawLine: ({ rgb, size, penMode, fromX, fromY, toX, toY }) ->
    if penMode is 'up' then return
    @_hasContent = true

    { model: { worldShape } } = @_latestDepInfo
    usePatchCoords(worldShape, @_ctx, (ctx) =>
      ctx.save()

      ctx.strokeStyle = rgbToCss(rgb)
      ctx.lineWidth   = size * worldShape.onePixel
      ctx.lineCap     = 'round'

      ctx.beginPath()
      ctx.moveTo(fromX, fromY)
      ctx.lineTo(toX, toY)
      useCompositing(compositingOperation(penMode), ctx, (ctx) ->
        ctx.stroke()
      )

      ctx.restore()
    )
    return

  _drawTurtleStamp: (turtleStamp) ->
    @_hasContent = true
    { model: { model, worldShape }, font: { fontFamily, fontSize } } = @_latestDepInfo
    mockTurtleObject = makeMockTurtleObject(turtleStamp)
    usePatchCoords(worldShape, @_ctx, (ctx) =>
      useCompositing(compositingOperation(turtleStamp.stampMode), ctx, (ctx) =>
        drawTurtle(
          worldShape,
          model.world.turtleshapelist,
          ctx,
          mockTurtleObject,
          true,
          fontSize,
          fontFamily
        )
      )
    )
    return

  _drawLinkStamp: (linkStamp) ->
    @_hasContent = true
    { model: { model, worldShape }, font: { fontFamily, fontSize } } = @_latestDepInfo
    mockLinkObject = makeMockLinkObject(linkStamp)
    usePatchCoords(worldShape, @_ctx, (ctx) =>
      useCompositing(compositingOperation(linkStamp.stampMode), ctx, (ctx) =>
        drawLink(
          model.world.linkshapelist,
          mockLinkObject...,
          worldShape,
          ctx,
          fontSize,
          fontFamily,
          true
        )
      )
    )
    return

  _importDrawing: (base64) ->
    @_clearDrawing()
    src =
      if base64.startsWith('data:')
        base64
      else
        # Raw base64 from workspace resources; detect type by magic bytes
        mimeType =
          if      base64.startsWith('R0lG') then 'image/gif'
          else if base64.startsWith('/9j/') then 'image/jpeg'
          else                                   'image/png'
        "data:#{mimeType};base64,#{base64}"
    image = new Image()
    image.onload = () =>
      canvasRatio = @_canvas.width / @_canvas.height
      imageRatio  = image.width / image.height
      width  = @_canvas.width
      height = @_canvas.height
      if (canvasRatio >= imageRatio)
        # canvas is "wider" than the image, use full image height and partial width
        width = (imageRatio / canvasRatio) * @_canvas.width
      else
        # canvas is "thinner" than the image, use full image width and partial height
        height = (canvasRatio / imageRatio) * @_canvas.height

      @_ctx.drawImage(image, (@_canvas.width - width) / 2, (@_canvas.height - height) / 2, width, height)
      @_hasContent = true
      @_dirty = true
      @_repaintCallback()
    image.src = src
    return

  # x and y coordinates are given in CSS pixels not accounting for quality.
  # Because this depends on some image to load, this method returns a Promise that resolves once the
  # image has actually been drawn to this DrawingLayer.
  importImage: (base64, x, y) ->
    ctx = @_ctx
    q = @_latestDepInfo.quality.quality
    image = new Image()
    new Promise((resolve) ->
      image.onload = ->
        useImageSmoothing(false, ctx, (ctx) =>
          ctx.drawImage(image, x * q, y * q, image.width * q, image.height * q)
        )
        resolve()
      image.src = base64 # What's the reason this line comes *after* setting image.onload? --Andre C
    )

export {
  DrawingLayer
}
