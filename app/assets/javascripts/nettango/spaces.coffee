import RactiveSpace from "./space.js"
import RactiveCodeMirror from "./code-mirror.js"
import NetTangoBlockDefaults from "./block-defaults.js"

RactiveSpaces = Ractive.extend({

  data: () -> {
    blockStyles:      undefined # NetTangoBlockStyles
    allTags:          []        # Array[String]
    lastCompiledCode: ""        # String
    playMode:         false     # Boolean
    popupMenu:        null      # RactivePopupMenu
    showCode:         true      # Boolean
    spaces:           []        # Array[NetTangoSpace]
  }

  on: {

    # (Context) => Unit
    'complete': (_) ->
      @observe('spaces', (spaces) ->
        spaces.forEach( (space, i) ->
          space.id      = i
          space.spaceId = "ntb-defs-#{i}"
        )
      )
      return

    # (Context, String, Boolean) => Unit
    '*.ntb-block-code-changed': (_) ->
      @updateCode()
      return

    # (Context, Integer) => Boolean
    '*.ntb-confirm-delete': (context, spaceNumber) ->
      @fire('show-confirm-dialog', context, {
        text: "Do you want to delete this workspace?"
      , approve: {
          text: "Yes, delete the workspace"
        , event: "ntb-delete-blockspace"
        , arguments: [spaceNumber]
        , target: this
        }
      , deny: { text: "No, keep workspace" }
      })
      return false

    '*.ntb-delete-blockspace': (_, spaceNumber) ->
      @deleteSpace(spaceNumber)
      return

    '*.ntb-clear-all-block-styles': (_) ->
      @clearBlockStyles()
      return

    # (Context, DuplicateBlockData) => Unit
    '*.ntb-duplicate-block-to': (_, { fromSpaceId, fromBlockIndex, toSpaceIndex }) ->
      spaces    = @get('spaces')
      fromSpace = spaces.filter( (s) -> s.spaceId is fromSpaceId )[0]
      toSpace   = spaces[toSpaceIndex]
      original  = fromSpace.defs.blocks[fromBlockIndex]
      copy      = NetTangoBlockDefaults.copyBlock(original)

      toSpace.defs.blocks.push(copy)

      @updateNetTango()
      return
  }

  # (Boolean) => Unit
  updateCode: () ->
    lastCode     = @get('lastCode')
    newCode      = @assembleCode(displayOnly = false)
    codeChanged  = lastCode isnt newCode
    @set('code', @assembleCode(displayOnly = true))
    if codeChanged
      @set('lastCode', newCode)
      @fire('ntb-code-dirty')
    return

  # () => Unit
  assembleCode: (displayOnly) ->
    spaces = @get('spaces')
    spaceCodes =
      spaces.map( (space) ->
        if displayOnly
          prefix = if spaces.length <= 1 then "" else "; Code for #{space.name}\n"
          "#{prefix}#{space.netLogoDisplay ? ""}".trim()
        else
          (space.netLogoCode ? "").trim()
      )
    spaceCodes.join("\n\n")

  # (NetTangoSpace) => NetTangoSpace
  createSpace: (spaceVals) ->
    spaces  = @get('spaces')
    id      = spaces.length
    spaceId = "ntb-defs-#{id}"
    defs    = if spaceVals.defs? then spaceVals.defs else { blocks: [], program: { chains: [] } }
    space = {
        id:              id
      , spaceId:         spaceId
      , name:            "Block Space #{id}"
      , width:           430
      , height:          500
      , defs:            defs
    }
    for propName in [ 'name', 'width', 'height' ]
      if(spaceVals.hasOwnProperty(propName))
        space[propName] = spaceVals[propName]

    @push('spaces', space)
    @fire('ntb-space-changed')
    return space

  deleteSpace: (spaceNumber) ->
    spaces    = @get('spaces')
    newSpaces = spaces.filter( (s) -> s.id isnt spaceNumber )
    newSpaces.forEach( (s, i) ->
      s.id      = i
      s.spaceId = "ntb-defs-#{i}"
    )
    @set('spaces', newSpaces)
    @updateCode()
    @fire('ntb-space-changed')
    @fire('ntb-recompile-all')
    return

  # () => Unit
  clearBlockStyles: () ->
    spaceComponents = @findAllComponents("tangoSpace")
    spaceComponents.forEach( (spaceComponent) -> spaceComponent.clearBlockStyles() )
    return

  # () => Unit
  updateNetTango: () ->
    spaceComponents = @findAllComponents("tangoSpace")
    spaceComponents.forEach( (spaceComponent) -> spaceComponent.refreshNetTango(spaceComponent.get("space"), true) )
    return

  # () => Array[String]
  getProcedures: () ->
    spaceComponents = @findAllComponents("tangoSpace")
    spaceComponents.flatMap( (spaceComponent) -> spaceComponent.getProcedures() )

  components: {
    tangoSpace:    RactiveSpace
    codeMirror:    RactiveCodeMirror
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-block-defs-list">
      {{#spaces:spaceNum }}
        <tangoSpace
          space="{{ this }}"
          playMode="{{ playMode }}"
          popupMenu="{{ popupMenu }}"
          blockStyles="{{ blockStyles }}"
        />
      {{/spaces }}
    </div>

    {{#if !playMode || showCode }}
    <label for="ntb-code"{{# !showCode}} class="ntb-hide-in-play"{{/}}>NetLogo Code</label>
    <codeMirror
      id="ntb-code"
      mode="netlogo"
      code="{{ code }}"
      config="{ readOnly: 'nocursor' }"
      extraClasses="[ 'ntb-code', 'ntb-code-large', 'ntb-code-readonly' ]"
    />
    {{/if !playMode || showCode }}
    """
    # coffeelint: enable=max_line_length
})

export default RactiveSpaces
