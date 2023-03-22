import ObjectUtils from "./object-utils.js"
import newModelNetTango from "./new-model-nettango.js"
import { netLogoOptionDefaults, netTangoOptionDefaults } from "./options.js"

createEmptyDefs = (blockStyles = {}) ->
  {
    version: NetTango.version
  , blocks: []
  , program: { chains: [] }
  , chainClose: "end"
  , blockStyles
  }

# (Number, String, String, BlockStyle) => NetTangoWorkspace
createWorkspace = (id, spaceId, name, blockStyles) ->
  {
    id
  , spaceId
  , name
  , height: 500
  , width: 430
  , defs: createEmptyDefs(blockStyles)
  }

# (String) => NetTangoProject
createProject = (title) ->
  {
    code:            newModelNetTango
    spaces:          []
    title:           title
    netLogoOptions:  ObjectUtils.clone(netLogoOptionDefaults)
    netTangoOptions: ObjectUtils.clone(netTangoOptionDefaults)
    extraCss:        ""
  }

export { createEmptyDefs, createProject, createWorkspace }
