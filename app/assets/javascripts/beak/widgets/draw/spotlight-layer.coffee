import { usePatchCoords, useWrapping } from "./draw-utils.js"
import { mergeInfo, Layer } from "./layer.js"
import { getDimensions, getSpotlightAgent, WATCH } from "./perspective-utils.js"

adjustSize = (size, worldShape) ->
  Math.max(size, worldShape.worldWidth / 16, worldShape.worldHeight / 16)

outerRadius = (patchsize) -> 10 / patchsize
middleRadius = (patchsize) -> 8 / patchsize
innerRadius = (patchsize) -> 4 / patchsize

# Names and values taken from org.nlogo.render.SpotlightDrawer
dimmed = "rgba(0, 0, 50, #{ 100 / 255 })"
spotlightInnerBorder = "rgba(200, 255, 255, #{ 100 / 255 })"
spotlightOuterBorder = "rgba(200, 255, 255, #{ 50 / 255 })"
clear = 'white' # for clearing with 'destination-out' compositing

drawCircle = (ctx, x, y, innerDiam, outerDiam, color) ->
  ctx.save()
  ctx.fillStyle = color
  ctx.beginPath()
  ctx.arc(x, y, outerDiam / 2, 0, 2 * Math.PI)
  ctx.arc(x, y, innerDiam / 2, 0, 2 * Math.PI, true)
  ctx.fill()
  ctx.restore()
  return

drawSpotlight = (ctx, worldShape, xcor, ycor, size, dimOther) ->
  { patchsize, actualMinX, actualMinY, worldWidth, worldHeight } = worldShape
  outer = outerRadius(patchsize)
  middle = middleRadius(patchsize)
  inner = innerRadius(patchsize)

  ctx.save()

  ctx.lineWidth = worldShape.onePixel
  ctx.beginPath()
  # Draw arc anti-clockwise so that it's subtracted from the fill. See the
  # fill() documentation and specifically the "nonzero" rule. BCH 3/17/2015
  if dimOther
    useWrapping(worldShape, ctx, xcor, ycor, size + outer, (ctx, x, y) =>
      ctx.moveTo(x, y) # Don't want the context to draw a path between the circles. BCH 5/6/2015
      ctx.arc(x, y, (size + outer) / 2, 0, 2 * Math.PI, true)
    )
    ctx.rect(actualMinX, actualMinY, worldWidth, worldHeight)
    ctx.fillStyle = dimmed
    ctx.fill()

  useWrapping(worldShape, ctx, xcor, ycor, size + outer, (ctx, x, y) =>
    drawCircle(ctx, x, y, size, size + outer, dimmed)
    drawCircle(ctx, x, y, size, size + middle, spotlightOuterBorder)
    drawCircle(ctx, x, y, size, size + inner, spotlightInnerBorder)
  )

  ctx.restore()
  return

class SpotlightLayer extends Layer
  # (-> { model: ModelObj }) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_getDepInfo)->
    super()
    @_latestDepInfo = {
      model: undefined
    }
    return

  getWorldShape: -> @_latestDepInfo.model.worldShape

  blindlyDrawTo: (ctx) ->
    { worldShape, model } = @_latestDepInfo.model
    watched = getSpotlightAgent(model)
    if not watched? then return
    usePatchCoords(worldShape, ctx, (ctx) =>
      [xcor, ycor, size] = getDimensions(watched)
      drawSpotlight(
        ctx,
        worldShape,
        xcor,
        ycor,
        adjustSize(size, worldShape),
        model.observer.perspective is WATCH
      )
    )
    return

  repaint: ->
    mergeInfo(@_latestDepInfo, @_getDepInfo())

export {
  SpotlightLayer
}
