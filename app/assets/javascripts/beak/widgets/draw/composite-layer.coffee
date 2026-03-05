import { mergeInfo, Layer } from "./layer.js"
import { setImageSmoothing, resizeCanvas, clearCtx, drawRectTo, drawFullTo } from "./draw-utils.js"

# CompositeLayer forms its image by sequentially copying over the images from its source layers.
class CompositeLayer extends Layer
  # (Array[Layer], -> { quality: QualityObj }) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_sourceLayers, @_getDepInfo) ->
    super()
    @_latestWorldShape = undefined
    @_latestDepInfo = {
      quality: undefined
    }
    @_canvas = document.createElement('canvas')
    @_ctx = @_canvas.getContext('2d')
    return

  getWorldShape: -> @_latestWorldShape

  getCanvas: -> @_canvas

  drawRectTo: (ctx, x, y, w, h) ->
    drawRectTo(@_canvas, ctx, x, y, w, h, @_latestWorldShape, @_latestDepInfo.quality.quality)
    return

  drawFullTo: (ctx) ->
    drawFullTo(@_canvas, ctx)
    return

  blindlyDrawTo: (context) ->
    context.drawImage(@_canvas, 0, 0)
    return

  repaint: ->
    changed = false
    for layer in @_sourceLayers
      if layer.repaint() then changed = true
    if mergeInfo(@_latestDepInfo, @_getDepInfo()) then changed = true
    if not changed then return false

    @_latestWorldShape = @_sourceLayers[0].getWorldShape()
    cleared = resizeCanvas(@_canvas, @_latestWorldShape, @_latestDepInfo.quality.quality)
    if not cleared then clearCtx(@_ctx)
    setImageSmoothing(@_ctx, false)
    for layer in @_sourceLayers
      layer.blindlyDrawTo(@_ctx)
    true

export {
  CompositeLayer
}
