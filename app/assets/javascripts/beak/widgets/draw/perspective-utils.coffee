# Enums defined by the engine output

# Agent type enum
turtleType = 1
patchType = 2
linkType = 3

# Perspective enum:
OBSERVE = 0
RIDE    = 1
FOLLOW  = 2
WATCH   = 3

# Returns the agent which should have a spotlight on it, or null if none exists.
# (AgentModel) -> Agent
getSpotlightAgent = (model) ->
  {observer: { perspective, targetagent }, turtles, links, patches} = model
  if perspective isnt OBSERVE and targetagent? and targetagent[1] >= 0
    [type, id] = targetagent
    switch type
      when turtleType then turtles[id]
      when patchType then patches[id]
      when linkType then links[id]
  else
    null

# Returns the agent which should be centered on the main view, or null if none exists.
# (AgentModel) -> Agent
getCenteredAgent = (model) ->
  {observer: { perspective, targetagent }, turtles, links, patches} = model
  if (perspective is RIDE or perspective is FOLLOW) and targetagent? and targetagent[1] >= 0
    [type, id] = targetagent
    switch type
      when turtleType then turtles[id]
      when patchType then patches[id]
      when linkType then links[id]
  else
    null

# (Agent) -> [number, number, number]
getDimensions = (agent) ->
  if agent.xcor?
    [agent.xcor, agent.ycor, 2 * agent.size]
  else if agent.pxcor?
    [agent.pxcor, agent.pycor, 2]
  else
    [agent.midpointx, agent.midpointy, agent.size]

export {
  getSpotlightAgent,
  getCenteredAgent,
  getDimensions,
  OBSERVE,
  RIDE,
  FOLLOW,
  WATCH
}
