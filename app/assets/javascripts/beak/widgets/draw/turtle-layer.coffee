import { mergeInfo, Layer } from "./layer.js"
import { drawTurtle } from "./draw-shape.js"
import { usePatchCoords } from "./draw-utils.js"
import { drawLink } from "./link-drawer.js"

# Yields each name in `breedNames` (skipping `unbreededName` if present), then always yields
# `unbreededName` last so unbreeded agents render on top and are always included regardless of
# whether the engine omits them from the breeds list.
breedNameGen = (unbreededName, breedNames) ->
  for breedName in breedNames
    if breedName isnt unbreededName
      yield breedName
  yield unbreededName

filteredByBreed = (unbreededName, agents, breeds) ->
  breededAgents = {}
  for _, agent of agents
    members = []
    breedName = agent.breed.toUpperCase()
    if not breededAgents[breedName]?
      breededAgents[breedName] = members
    else
      members = breededAgents[breedName]
    members.push(agent)
  for breedName from breedNameGen(unbreededName, breeds)
    if breededAgents[breedName]?
      members = breededAgents[breedName]
      for agent in members
        yield agent

class TurtleLayer extends Layer
  # (-> { model: ModelObj, font: FontObj }) -> Unit
  # see "./layer.coffee" for type info
  constructor: (@_getDepInfo) ->
    super()
    @_latestDepInfo = {
      model: undefined,
      font: undefined
    }
    return

  getWorldShape: -> @_latestDepInfo.model.worldShape

  blindlyDrawTo: (context) ->
    {
      model: { model: { world, turtles, links }, worldShape },
      font: { fontFamily, fontSize }
    } = @_latestDepInfo
    usePatchCoords(
      worldShape,
      context,
      (context) =>
        for link from filteredByBreed('LINKS', links, world.linkbreeds ? [])
          drawLink(
            world.linkshapelist
            link,
            turtles[link.end1],
            turtles[link.end2],
            worldShape,
            context,
            fontSize,
            fontFamily
          )
        for turtle from filteredByBreed('TURTLES', turtles, world.turtlebreeds ? [])
          drawTurtle(
            worldShape,
            world.turtleshapelist,
            context,
            turtle,
            false,
            fontSize,
            fontFamily
          )
    )
    return

  repaint: ->
    mergeInfo(@_latestDepInfo, @_getDepInfo())

export {
  TurtleLayer
}
