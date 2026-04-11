import { getEquivalentAgent } from "./draw/agent-conversion.js"

Turtle = tortoise_require('engine/core/turtle')
Patch  = tortoise_require('engine/core/patch')
Link   = tortoise_require('engine/core/link')

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

    minClickPixels = 12
    offset = Math.max(modelTurtle.size * 0.5, minClickPixels / agentModel.world.patchsize)

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

# Groups same-type agents (all turtles or all links) by breed, returning submenu entries for breeds
# with 2+ agents when multipleBreeds is true, or for any breed with more than SUBMENU_THRESHOLD agents.
# Unbreeded agents use breed name 'turtles' or 'links'.
# ((SetInspectAction) -> Unit, Array[Agent], boolean) -> Array[ContextMenuOption]
SUBMENU_THRESHOLD = 15

groupedAgentOptions = (setInspect, agents, multipleBreeds) ->
  return [] if agents.length is 0
  byBreed = {}
  for agent in agents
    breed = agent.getBreedName()
    byBreed[breed] ?= []
    byBreed[breed].push(agent)
  # Base breed ("turtles"/"links") first, then remaining breeds alphabetically
  breeds = Object.keys(byBreed).sort((a, b) ->
    aLower = a.toLowerCase()
    bLower = b.toLowerCase()
    if aLower is 'turtles' or aLower is 'links' then -1
    else if bLower is 'turtles' or bLower is 'links' then 1
    else aLower.localeCompare(bLower)
  )
  result = []
  for breed in breeds
    breedAgents = byBreed[breed]
    if breedAgents.length > SUBMENU_THRESHOLD or (multipleBreeds and breedAgents.length >= 2)
      result.push({
        text:      "inspect #{breed.toLowerCase()}...",
        isEnabled: true,
        isSubmenu: true,
        submenu:   breedAgents.map(agentToContextMenuOption(setInspect))
      })
    else
      for agent in breedAgents
        result.push(agentToContextMenuOption(setInspect)(agent))
  result

# Converts a list of agents near a click point into context menu options.
# The patch (if any) is always first. Turtles and links are grouped by breed, with submenus used
# for any breed with 2+ agents when there are multiple breed groups across turtles and links combined.
# ((SetInspectAction) -> Unit) -> Array[Agent] -> Array[ContextMenuOption]
agentsToContextMenuOptions = (setInspect) -> (agents) ->
  patches = agents.filter((a) -> a instanceof Patch)
  turtles = agents.filter((a) -> a instanceof Turtle)
  links   = agents.filter((a) -> a instanceof Link)
  turtleBreedCount = new Set(turtles.map((a) -> a.getBreedName())).size
  linkBreedCount   = new Set(links.map((a) -> a.getBreedName())).size
  multipleBreeds   = turtleBreedCount + linkBreedCount > 1
  patches.map(agentToContextMenuOption(setInspect))
    .concat(groupedAgentOptions(setInspect, turtles, multipleBreeds))
    .concat(groupedAgentOptions(setInspect, links, multipleBreeds))

export {
  getClickedAgents,
  agentToContextMenuOption,
  agentsToContextMenuOptions
}
