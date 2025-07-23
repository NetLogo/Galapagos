import ObjectUtils from "./object-utils.js"
import newModelNetTango from "./new-model-nettango.js"
import { netLogoOptionDefaults, netTangoOptionDefaults } from "./options.js"

NETTANGO_PROJECT_VERSION = 1

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
    projectVersion:  NETTANGO_PROJECT_VERSION
  }

# () => NetTangoProject
createNewProject = () ->
  project = createProject("New Project")
  project.spaces = [createWorkspace(0, "ntb-defs-0", "Block Space 0")]
  project

export { NETTANGO_PROJECT_VERSION, createEmptyDefs, createNewProject, createProject, createWorkspace }
