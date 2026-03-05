import { getEquivalentAgent } from "./draw/agent-conversion.js"

# Given a world and a view into that world, returns a list of all the agents around the specified point. The point is
# specified in DOM coordinates relative to the given view.
# (AgentModel) -> (World, View, number, number) -> [Agent]
getClickedAgents = (agentModel) -> (world, view, clientX, clientY) ->
  { left, top } = view.getBoundingClientRect()
  agentList = []
  mouseX = view.xPixToPcor(clientX - left)
  mouseY = view.yPixToPcor(clientY - top)

  patchHere = world.getPatchAt(mouseX, mouseY)
  if patchHere? then agentList.push(patchHere)

  # converts an agent to its equivalent agent in the ViewController's AgentModel
  getEquiv = getEquivalentAgent(agentModel)

  world.links().iterator().forEach((link) ->
    [modelLink, _] = getEquiv(link)
    if modelLink['hidden?']
      # don't add hidden links
      return

    [{ xcor: x1, ycor: y1 }, { xcor: x2, ycor: y2 }] = [link.end1, link.end2]
    if world.topology.distanceToLine(x1, y1, x2, y2, mouseX, mouseY) < modelLink.thickness + 0.5
      agentList.push(link)
  )

  world.turtles().iterator().forEach((turtle) ->
    [modelTurtle, _] = getEquiv(turtle)
    if modelTurtle['hidden?']
      # don't add hidden turtles
      return

    offset = modelTurtle.size * 0.5
    if offset * agentModel.world.patchsize < 3
      offset += 3 / agentModel.world.patchsize

    if world.topology.distance(mouseX, mouseY, turtle) <= offset
      agentList.push(turtle)
  )

  agentList

# ((SetInspectAction) -> Unit) -> (Agent) -> ContextMenuOption
# see "./ractives/contextable.coffee"
agentToContextMenuOption = (setInspect) -> (agent) -> {
  text: "inspect #{agent.getName()}"
  isEnabled: true,
  action: -> setInspect({ type: 'add', agents: [agent], monitor: true })
}

export {
  getClickedAgents,
  agentToContextMenuOption
}
