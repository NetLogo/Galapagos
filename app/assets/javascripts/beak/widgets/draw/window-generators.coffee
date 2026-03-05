import { extractWorldShape } from "./draw-utils.js"
import { getDimensions, getCenteredAgent } from "./perspective-utils.js"

###
This file defines generators (more precisely, iterators) that are used to get the window that a
specific view should be looking at. Each value returned should be of Rectangle type:
- { x, y }, meaning a rectangle with its top left corner at (x, y) and the same dimensions as the
  previous rectangle.
- { x, y, h }, meaning a rectangle with a new corner and height; the width should be
  whatever it takes to keep the same aspect ratio as the previous rectangle.
- { x, y, h, w }, meaning a rectangle with completely new dimensions.
In addition, this "Rectangle" type may have a property `canvasHeight` that specifies the height, in CSS pixels, of the
actual canvas.
###

# The `WorldShape` returned by `getWorldShape` must agree with the `AgentModel` returned by `getModel`.
# Sucks that for proper memoization of the world shape, we have to pass two functions that must agree.
# ((Unit) -> Model, (Unit) -> WorldShape) -> Iterator<_>
followObserver = (getModel, getWorldShape) ->
  loop
    { actualMinX: x, actualMaxY: y, worldWidth: w, worldHeight: h, patchsize } = getWorldShape()

    # Account for the possibility of having to center on an agent
    if (centeredAgent = getCenteredAgent(getModel()))?
      [agentX, agentY, _] = getDimensions(centeredAgent)
      x = agentX - w / 2
      y = agentY + h / 2

    yield { x, y, w, h, canvasHeight: h * patchsize }

# Returns an iterator that generates windows following the specified agent.
# `zoomLevel` is a number representing how much of the screen the agent takes up
# where 1 means the agent fills up the whole screen and values close to 0 mean
# the agent is infinitesimally small
# (number, Agent, number) -> Iterator<Rectangle>
# where Rectangle is defined above in the comment;
# can also safely set the public properties `agent` and `zoomLevel`
followAgentWithZoom = (canvasHeight, agent, zoomLevel, maxRadius) -> return {
  agent,
  zoomLevel,
  maxRadius,
  next: ->
    [x, y, size] = getDimensions(@agent) # note that for some reason this is actually twice the agent size
    size = size / 2
    if size is 0 then size = 0.5
    r = Math.min(size / @zoomLevel / 2, maxRadius)
    return {
      value: {
        x: x - r,
        y: y + r,
        w: r * 2,
        h: r * 2,
        canvasHeight
      },
      done: false
    }
}

export {
  followObserver,
  followAgentWithZoom
}
