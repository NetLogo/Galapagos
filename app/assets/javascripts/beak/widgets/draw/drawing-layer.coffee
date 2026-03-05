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
  # (-> { model: ModelObj, quality: QualityObj, font: FontObj }) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_getDepInfo) ->
    super()
    @_latestDepInfo = {
      model: undefined,
      quality: undefined,
      font: undefined
    }
    @_canvas = document.createElement('canvas')
    @_ctx = @_canvas.getContext('2d')
    return

  getWorldShape: -> @_latestDepInfo.model.worldShape

  blindlyDrawTo: (ctx) ->
    ctx.drawImage(@_canvas, 0, 0)
    return

  repaint: ->
    if not mergeInfo(@_latestDepInfo, @_getDepInfo()) then return false

    { model: { model, worldShape }, quality: { quality } } = @_latestDepInfo
    resizeCanvas(@_canvas, worldShape, quality)
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
    return

  _drawLine: ({ rgb, size, penMode, fromX, fromY, toX, toY }) ->
    if penMode is 'up' then return

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
    _clearDrawing()
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
    image.src = base64
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
