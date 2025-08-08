import genOldFormatRoles from "./hnw-old-format-generator.js"
import genXMLRoles from "./hnw-xml-format-generator.js"

# (String) => Object[Any]
generateHNWConfig = (nlogo) ->

  genRoles = if nlogo.trim().startsWith("<?xml") then genXMLRoles else genOldFormatRoles
  [mainRole, clientRole] = genRoles(nlogo)

  outConfig =
    { roles:           [mainRole, clientRole]
    , onIterate:       ""
    , onStart:         ""
    , targetFrameRate: 20
    , version:         "hnw-beta-1"
    , type:            "hubnet-web"
    }

  outConfig

export default generateHNWConfig
