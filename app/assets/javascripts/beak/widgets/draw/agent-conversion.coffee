Turtle = tortoise_require('engine/core/turtle')
Patch = tortoise_require('engine/core/patch')
Link = tortoise_require('engine/core/link')

# Converts the actual agent object (such as one you'd obtain from using the `workspace` global variable) into the
# equivalent agent from the AgentModel. Also returns either 'turtle', 'patch', 'link', or 'dead' depending on the type
# of agent and whether it is dead.
# (Agent) -> [Agent, 'turtle' | 'patch' | 'link']
getEquivalentAgent = (agentModel) -> (agent) ->
  if agent.isDead() then return [undefined, 'dead']
  switch
    when agent instanceof Turtle then [agentModel.turtles[agent.id], 'turtle']
    when agent instanceof Patch then [agentModel.patches[agent.id], 'patch']
    when agent instanceof Link then [agentModel.links[agent.id], 'link']
    else throw new Error("agent is not a valid type")

export {
  getEquivalentAgent
}
