import { usePatchCoords } from "./draw-utils.js"
import { drawLabel } from "./draw-shape.js"
import { mergeInfo, Layer } from "./layer.js"
import { netlogoColorToRGB } from "/colors.js"

clearPatches = (ctx) ->
  ctx.fillStyle = "black"
  ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height)
  return

colorPatches = (ctx, worldShape, patches) ->
  # Make sure that the canvas is properly sized to the world, one pixel per patch.
  # Avoids resizing the canvas if possible, as that is an expensive operation. (https://stackoverflow.com/a/6722031)
  { worldWidth, worldHeight } = worldShape
  if ctx.canvas.width isnt worldWidth then ctx.canvas.width = worldWidth
  if ctx.canvas.height isnt worldHeight then ctx.canvas.height = worldHeight
  imageData = ctx.createImageData(worldWidth, worldHeight)
  numPatches = worldWidth * worldHeight
  for i in [0...numPatches] when (patch = patches[i])?
    j = 4 * i
    [r, g, b] = netlogoColorToRGB(patch.pcolor)
    imageData.data[j + 0] = r
    imageData.data[j + 1] = g
    imageData.data[j + 2] = b
    imageData.data[j + 3] = 255
  ctx.putImageData(imageData, 0, 0)
  return

labelPatches = (ctx, worldShape, patches, fontSize, font) ->
  usePatchCoords(
    worldShape,
    ctx,
    (ctx) ->
      for _, patch of patches
        drawLabel(
          worldShape,
          ctx,
          patch.pxcor + 0.5,
          patch.pycor - 0.5,
          patch.plabel,
          patch['plabel-color'],
          fontSize,
          font
        )
  )
  return

# Works by creating a scratchCanvas that has a pixel per patch. Those pixels
# are colored accordingly. Then, the scratchCanvas is drawn onto the main
# canvas scaled. This is very, very fast. It also prevents weird lines between
# patches.
class PatchLayer extends Layer
  # (-> { model: ModelObj, font: FontObj }) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_getDepInfo) ->
    super()
    @_latestDepInfo = {
      model: undefined,
      font: undefined
    }
    @_canvas = document.createElement('canvas')
    @_ctx = @_canvas.getContext('2d')
    return

  getWorldShape: -> @_latestDepInfo.model.worldShape

  blindlyDrawTo: (context) ->
    { model: { model, worldShape }, font: { fontFamily, fontSize }} = @_latestDepInfo
    context.drawImage(@_canvas, 0, 0, context.canvas.width, context.canvas.height)
    if model.world.patcheswithlabels
      labelPatches(context, worldShape, model.patches, fontSize, fontFamily)
    return

  repaint: ->
    if not mergeInfo(@_latestDepInfo, @_getDepInfo()) then return false
    { model, worldShape } = @_latestDepInfo.model

    if model.world.patchesallblack
      clearPatches(@_ctx)
    else
      colorPatches(@_ctx, worldShape, model.patches)
    true

export {
  PatchLayer
}
