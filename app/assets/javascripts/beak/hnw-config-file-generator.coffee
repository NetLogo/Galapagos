import genXMLRoles from "./hnw-xml-format-generator.js"

# (String) => Object[Any]
generateHNWConfig = (nlogox) ->

  [mainRole, clientRole] = genXMLRoles(nlogox)

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
