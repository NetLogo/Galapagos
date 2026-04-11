import { mergeInfo, Layer } from "./layer.js"
import { usePatchCoords } from "./draw-utils.js"
import { netlogoColorToCSS } from "/colors.js"
import { drawTurtle } from "./draw-shape.js"
import { getEquivalentAgent } from "./agent-conversion.js"
import { useWrapping } from "./draw-utils.js"
import { getSpotlightAgent } from "./perspective-utils.js"

# Turns a string representing a valid CSS color into the same color, but with 0 alpha. If the string is not an
# `RGBColorString`, then null is returned.
# (string, number) -> RGBColorString | null
# where `RGBColorString` is just a string of the form "rgb[a](RED, GREEN, BLUE[, ALPHA])" representing a valid CSS color
setTransparency = do ->
  regex = /^rgba?\((?<r>\d+), (?<g>\d+), (?<b>\d+)(?:, .*)?\)$/
  (colorString, newAlpha) ->
    match = colorString.match(regex)
    if not match?
      console.error("Color string `%s` failed to match regex. Might want to look into that.", colorString)
      return null
    { r, g, b } = match.groups
    "rgb(#{r}, #{g}, #{b}, #{newAlpha})"

# Modifies canvas state. Draws two concentric circles around (x, y): a light inner ring and a dark outer ring.
# (ctx, number, number, number, number) -> Unit
drawInspectCircles = (ctx, x, y, radius, thickness) ->
  ctx.lineWidth = thickness
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.4)'
  ctx.beginPath()
  ctx.arc(x, y, radius, 0, 2 * Math.PI)
  ctx.stroke()
  ctx.strokeStyle = 'rgba(0, 0, 0, 0.4)'
  ctx.beginPath()
  ctx.arc(x, y, radius + thickness, 0, 2 * Math.PI)
  ctx.stroke()

# Modifies canvas state
highlightUnitSquare = (ctx, x, y, onePixel) ->
  ctx.fillStyle = "rgba(255, 255, 255, 0.5)"
  ctx.fillRect(x - 0.5, y - 0.5, 1, 1)

# Modifies canvas state
glowLine = (ctx, x1, y1, x2, y2, thickness, color) ->
  ctx.lineWidth = thickness
  ctx.strokeStyle = setTransparency(color, 0.5)
  ctx.beginPath()
  ctx.moveTo(x1, y1)
  ctx.lineTo(x2, y2)
  ctx.stroke()

class HighlightLayer extends Layer
  # (-> { model: ModelObj, highlight: HighlightObj }) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_getDepInfo) ->
    super()
    @_latestDepInfo = {
      model: undefined,
      highlight: undefined
    }
    return

  getWorldShape: -> @_latestDepInfo.model.worldShape

  blindlyDrawTo: (ctx) ->
    { highlight: { highlightedAgents, selectionCircle }, model: { model, worldShape } } = @_latestDepInfo
    toModelAgent = getEquivalentAgent(model) # function that converts from actual agent object to AgentModel analogue
    watchTarget = getSpotlightAgent(model)
    if selectionCircle?
      drawSelect = (ctx) ->
        { xcor, ycor, radius } = selectionCircle
        thickness = 2 * worldShape.onePixel
        drawInspectCircles(ctx, xcor, ycor, radius, thickness)
        return
      usePatchCoords(worldShape, ctx, drawSelect)

  repaint: ->
    mergeInfo(@_latestDepInfo, @_getDepInfo())

export {
  HighlightLayer
}
