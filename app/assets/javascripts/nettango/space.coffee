import CodeUtils from "/beak/widgets/code-utils.js"
import { RactiveTwoWayLabeledInput } from "/beak/widgets/ractives/subcomponent/labeled-input.js"
import RactiveJsonEditor from "./json-editor.js"
import NetTangoRewriter from "./rewriter.js"
import NetTangoBlockDefaults from "./block-defaults.js"

dele = { eventName: 'ntb-delete-block',         name: 'delete' }
edit = { eventName: 'ntb-show-edit-block-form', name: 'edit' }
up   = { eventName: 'ntb-block-up',             name: 'move up' }
dn   = { eventName: 'ntb-block-down',           name: 'move down' }
dup  = { eventName: 'ntb-duplicate-block',      name: 'duplicate' }

modifyBlockMenuItems = [dele, edit, up, dn, dup]

RactiveSpace = Ractive.extend({

  data: () -> {
    blockStyles:   null  # NetTangoBlockStyles
    defsJson:      ""    # String
    netLogoCode:   ""    # String
    playMode:      false # Boolean
    space:         null  # NetTangoSpace
  }

  on: {

    # (Context) => Unit
    'render': (_) ->
      space = @get('space')
      @refreshNetTango(space, false)

      @fire('ntb-block-code-changed')

      @observe('space', ->
        @updateNetTango(@get('space'), false)
        return
      , { defer: true, strict: true, init: false }
      )

      return

    # (Context, NetTangoSpace) => Boolean
    'ntb-show-block-defaults': ({ event: { pageX, pageY } }, space) ->
      NetTangoBlockDefaults.blocks.eventName = 'ntb-show-create-block-form'
      @fire('show-popup-menu', {}, this, pageX, pageY, NetTangoBlockDefaults.blocks)
      return false

    # (Context, NetTangoSpace) => Boolean
    'ntb-show-block-modify': ({ event: { pageX, pageY } }, space) ->
      spaces     = @parent.get("spaces")
      modifyMenu = @createModifyMenuContent(space, spaces)
      @fire('show-popup-menu', {}, this, pageX, pageY, modifyMenu)
      return false

    # (Context, Integer) => Unit
    '*.ntb-delete-block': (_, blockIndex) ->
      space = @get('space')
      @splice('space.defs.blocks', blockIndex, 1)
      @updateNetTango(space, true)
      @fire('ntb-recompile-all')
      return

    # (Context, NetTangoSpace) => Unit
    '*.ntb-apply-json-to-space': (_, newJson) ->
      try
        newDefs = JSON.parse(newJson)
      catch ex
        @fire('ntb-error', {}, 'json-apply', ex)
        return

      @set("space.defs", newDefs)
      space = @get('space')
      @updateNetTango(space, false)
      @fire('ntb-space-changed')
      return

    # (Context) => Unit
    'ntb-space-title-changed': (_) ->
      @fire("ntb-block-code-changed")
      @fire("ntb-space-changed")
      return

    # (Context) => Unit
    '*.ntb-size-change': (_) ->
      space = @get('space')
      @updateNetTango(space, true)
      return

    # (Context, NetTangoBlock) => Unit
    '*.ntb-show-create-block-form': (_, blockBase) ->
      space = @get('space')
      block = NetTangoBlockDefaults.copyBlock(blockBase)
      @fire(
        'show-block-edit-form'
      , this
      , space.name
      , block
      , null
      , "Add New Block"
      , "ntb-block-added"
      , "Discard New Block"
      )
      return

    # (Context, NetTangoBlock) => Unit
    '*.ntb-block-added': (block) ->
      space = @get('space')
      @push("space.defs.blocks", block)
      @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-show-edit-block-form': (_, blockIndex) ->
      space = @get('space')
      block = space.defs.blocks[blockIndex]
      @fire(
        'show-block-edit-form'
      , this
      , space.name
      , block
      , blockIndex
      , "Update Block"
      , "ntb-block-updated"
      , "Discard Changes"
      )
      return

    # (Context, NetTangoBlock, Integer) => Unit
    '*.ntb-block-updated': (block, blockIndex) ->
      space = @get('space')
      space.defs.blocks[blockIndex] = block
      @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-block-up': (_, blockIndex) ->
      space = @get('space')
      if (blockIndex > 0)
        swap = space.defs.blocks[blockIndex - 1]
        space.defs.blocks[blockIndex - 1] = space.defs.blocks[blockIndex]
        space.defs.blocks[blockIndex] = swap
        @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-block-down': (_, blockIndex) ->
      space = @get('space')
      if (blockIndex < (space.defs.blocks.length - 1))
        swap = space.defs.blocks[blockIndex + 1]
        space.defs.blocks[blockIndex + 1] = space.defs.blocks[blockIndex]
        space.defs.blocks[blockIndex] = swap
        @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-duplicate-block': (_, blockIndex) ->
      space    = @get('space')
      original = space.defs.blocks[blockIndex]
      copy = NetTangoBlockDefaults.copyBlock(original)
      @splice("space.defs.blocks", blockIndex + 1, 0, copy)
      @updateNetTango(space, true)
      return

  }

  # (NetTangoSpace | null) => String
  getNetTangoContainerId: (space) ->
    if not space then space = @get("space")
    "#{space.spaceId}-canvas"

  # (NetTangoSpace, String) => Unit
  setSpaceNetLogo: (space, containerId) ->
    space.netLogoCode    = NetTango.exportCode(containerId, NetTangoRewriter.formatDisplayAttribute).trim()
    space.netLogoDisplay = NetTango.exportCode(containerId).trim()
    return

  dispatchNetTangoEvent: (ntContainerId, event) ->
    if (@get('space')?)
      # `space` can change after we `render`, so do not use the one we already got above -JMB 11/2018
      s = @get('space')
      @handleNetTangoEvent(s, ntContainerId, event)
    return

  # (NetTangoSpace, String, Event) => Unit
  handleNetTangoEvent: (space, containerId, event) ->
    space.defs.program.chains = NetTango.save(containerId).program.chains
    @setSpaceNetLogo(space, containerId)
    switch event.type

      when "block-changed", "attribute-changed"
        @saveNetTango()
        @fire('ntb-block-code-changed')
        @fire('ntb-space-changed')

      when "menu-item-clicked"
        playMode = @get("playMode")
        if (not playMode)
          space      = @get("space")
          blockIndex = space.defs.blocks.findIndex( (block) -> block.id is event.blockId )
          block      = space.defs.blocks[blockIndex]
          @fire(
            'show-block-edit-form'
          , this
          , space.name
          , block
          , blockIndex
          , "Update Block"
          , "ntb-block-updated"
          , "Discard Changes"
          )

      when "menu-item-context-menu"
        playMode = @get("playMode")
        if (not playMode)
          space      = @get("space")
          blockIndex = space.defs.blocks.findIndex( (block) -> block.id is event.blockId )
          block      = space.defs.blocks[blockIndex]
          spaces     = @parent.get("spaces")
          modifyMenu = @createModifyMenu(block, blockIndex, space, spaces)
          @fire('show-popup-menu', {}, this, event.x, event.y, modifyMenu)

    return

  # (NetTangoSpace, Boolean) => Unit
  refreshNetTango: (space, keepOldChains) ->
    containerId = @getNetTangoContainerId(space)

    newChains = if (keepOldChains)
      NetTango.save(containerId).program.chains
    else
      space.defs.program.chains

    spaceDef = {
      version:     space.defs.version
    , height:      space.height
    , width:       space.width
    , blockStyles: @get("blockStyles")
    , blocks:      space.defs.blocks
    , expressions: space.defs.expressions
    , program:     { chains: newChains }
    }
    try
      NetTango.restore("NetLogo", containerId, spaceDef, NetTangoRewriter.formatDisplayAttribute)
    catch ex
      @fire('ntb-error', {}, 'workspace-refresh', ex)
      return

    @saveNetTango(containerId)
    @setSpaceNetLogo(space, containerId)
    NetTango.onProgramChanged(containerId, (args...) => @dispatchNetTangoEvent(args...))
    return

  # (String|null) => Unit
  saveNetTango: (containerId) ->
    if not containerId then containerId = @getNetTangoContainerId()
    netTangoData = NetTango.save(containerId)
    # We only use project-wide default styles, so delete the workspace ones when we save
    # off the data -Jeremy B June 2021
    delete netTangoData.blockStyles
    @set("space.defs", netTangoData)
    @set("defsJson",   JSON.stringify(netTangoData, null, '  '))
    return

  # (NetTangoSpace, Boolean) => Unit
  updateNetTango: (space, keepOldChains) ->
    @refreshNetTango(space, keepOldChains)

    @fire('ntb-block-code-changed')
    if keepOldChains then @fire('ntb-space-changed')
    return

  # (NetTangoBlock, Integer, NetTangoSpace, Array[NetTangoSpace]) => Content
  createModifyMenu: (block, blockIndex, space, spaces) ->
    items          = modifyBlockMenuItems.map( (x) -> Object.assign({ data: blockIndex }, x) )
    dupToSpaceItem = @createDuplicateToSpaceMenuItem(blockIndex, space, spaces)
    if (dupToSpaceItem isnt null)
      items.push(dupToSpaceItem)

    {
      name:  block.action
      items
    }

  # (Integer, NetTangoSpace, Array[NetTangoSpace]) => MenuItem | null
  createDuplicateToSpaceMenuItem: (blockIndex, space, spaces) ->
    otherSpaces = spaces
      .map( (s, index) -> return { space: s, index } )
      .filter( (s) -> space.spaceId isnt s.space.spaceId )

    if otherSpaces.length is 0
      return null

    if otherSpaces.length is 1
      return {
        name: "duplicate to #{otherSpaces[0].space.name}"
        eventName: "ntb-duplicate-block-to"
        data: { fromSpaceId: space.spaceId, fromBlockIndex: blockIndex, toSpaceIndex: otherSpaces[0].index }
      }

    return {
      name: "duplicate to",
      items: otherSpaces.map( (s) -> {
        name: s.space.name
        eventName: "ntb-duplicate-block-to"
        data: { fromSpaceId: space.spaceId, fromBlockIndex: blockIndex, toSpaceIndex: s.index }
      })
    }

  # (NetTangoSpace, Array[NetTangoSpace]) => Content
  createModifyMenuContent: (space, spaces) ->
    items = for block, blockIndex in space.defs.blocks
      @createModifyMenu(block, blockIndex, space, spaces)

    {
      name: "_",
      items: items
    }

  # () => Unit
  clearBlockStyles: () ->
    space = @get('space')
    for block in space.defs.blocks
      for prop in [ 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
        if block.hasOwnProperty(prop)
          delete block[prop]
    @set('space', space)
    @updateNetTango(space, true)
    return

  # () => Array[String]
  getProcedures: () ->
    space = @get('space')
    Object.keys(CodeUtils.findProcedureNames(space.netLogoCode, "upper"))

  components: {
    jsonEditor: RactiveJsonEditor
    labeledInput: RactiveTwoWayLabeledInput
  }

  template:
    # coffeelint: disable=max_line_length
    """
    {{# space }}

    <div class="ntb-block-def">

      <div class="ntb-space-title-bar">

        {{# playMode }}
          <div class="ntb-space-title-play">{{ name }}</div>

        {{else}}
          <input type="text" class="ntb-space-title" value="{{ name }}" on-change="ntb-space-title-changed">

        {{/playMode}}

      </div>

      {{# !playMode }}

      <div class="ntb-block-defs-controls" >

          <button id="add-block-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-show-block-defaults', this ]">Add Block ▼</button>

          <button id="modify-block-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-show-block-modify', this ]" {{# defs.blocks.length === 0 }}disabled{{/}}>Modify Block ▼</button>

          <button id="delete-space-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-confirm-delete', id ]" >Delete Block Space</button>

          <labeledInput id="width-{{ spaceId }}" name="width" type="number" value="{{ width }}" labelStr="Width"
            onChange="ntb-size-change" min="50" max="9000" divClass="ntb-flex-column" class="ntb-input" />

          <labeledInput id="height-{{ spaceId }}" name="height" type="number" value="{{ height }}" labelStr="Height"
            onChange="ntb-size-change" min="50" max="9000" divClass="ntb-flex-column" class="ntb-input" />

      </div>

      {{/ !playMode }}

      <div id="{{ spaceId }}" class="ntb-canvas" >
        <div id="{{ spaceId }}-canvas" />
      </div>

      {{# !playMode }}

      <jsonEditor id="{{ spaceId }}-json" json={{ defsJson }} />

      {{/ !playMode }}

    </div>

    {{/ space }}
    """
    # coffeelint: enable=max_line_length
})

export default RactiveSpace
