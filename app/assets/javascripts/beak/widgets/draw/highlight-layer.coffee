import { mergeInfo, Layer } from "./layer.js"
import { usePatchCoords } from "./draw-utils.js"
import { netlogoColorToCSS } from "/colors.js"
import { getEquivalentAgent } from "./agent-conversion.js"
import { useWrapping } from "./draw-utils.js"

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

# Modifies canvas state.
glowPoint = (ctx, x, y, r, color) ->
  grad = ctx.createRadialGradient(x, y, 0, x, y, r)
  grad.addColorStop(0, color)
  grad.addColorStop(1, setTransparency(color, 0) ? 'transparent')
  ctx.fillStyle = grad
  ctx.beginPath()
  ctx.arc(x, y, r, 0, 2 * Math.PI)
  ctx.fill()

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
    { highlight: { highlightedAgents }, model: { model, worldShape } } = @_latestDepInfo
    toModelAgent = getEquivalentAgent(model) # function that converts from actual agent object to AgentModel analogue
    usePatchCoords(worldShape, ctx, (ctx) =>
      for agent in highlightedAgents
        [agent, type] = toModelAgent(agent)
        switch type
          when 'turtle'
            radius = agent.size
            useWrapping(worldShape, ctx, agent.xcor, agent.ycor, 2 * radius, (ctx, x, y) ->
              glowPoint(ctx, x, y, radius, netlogoColorToCSS(agent.color))
            )
          when 'patch'
            highlightUnitSquare(ctx, agent.pxcor, agent.pycor, worldShape.onePixel)
          when 'link'
            { end1, end2, color, thickness } = agent
            { xcor: x1, ycor: y1 } = model.turtles[end1]
            { xcor: x2, ycor: y2 } = model.turtles[end2]
            glowLine(ctx, x1, y1, x2, y2, Math.max(2 * thickness, 5 * worldShape.onePixel), netlogoColorToCSS(color))
      return
    )

  repaint: ->
    mergeInfo(@_latestDepInfo, @_getDepInfo())

export {
  HighlightLayer
}
