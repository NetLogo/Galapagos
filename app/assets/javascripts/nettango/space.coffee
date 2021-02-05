dele = { eventName: 'ntb-delete-block',         name: 'delete' }
edit = { eventName: 'ntb-show-edit-block-form', name: 'edit' }
up   = { eventName: 'ntb-block-up',             name: 'move up' }
dn   = { eventName: 'ntb-block-down',           name: 'move down' }
dup  = { eventName: 'ntb-duplicate-block',      name: 'duplicate' }

modifyBlockMenuItems = [dele, edit, up, dn, dup]

window.RactiveSpace = Ractive.extend({

  data: () -> {
    blockEditForm: null  # RactiveBlockForm
    blockStyles:   null  # NetTangoBlockStyles
    codeIsDirty:   false # Boolean
    confirmDialog: null  # RactiveConfirmDialog
    defsJson:      ""    # String
    netLogoCode:   ""    # String
    playMode:      false # Boolean
    popupMenu:     null  # RactivePopupMenu
    space:         null  # NetTangoSpace
  }

  on: {

    # (Context) => Unit
    'render': (_) ->
      space = @get('space')
      @initNetTango(space)

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
      @get('popupMenu').popup(this, pageX, pageY, NetTangoBlockDefaults.blocks)
      return false

    # (Context, NetTangoSpace) => Boolean
    'ntb-show-block-modify': ({ event: { pageX, pageY } }, space) ->
      spaces     = @parent.get("spaces")
      modifyMenu = @createModifyMenuContent(space, spaces)
      @get('popupMenu').popup(this, pageX, pageY, modifyMenu)
      return false

    # (Context, Integer) => Unit
    '*.ntb-delete-block': (_, blockIndex) ->
      space = @get('space')
      @splice("space.defs.blocks", blockIndex, 1)
      @updateNetTango(space, true)
      return

    # (Context, NetTangoSpace) => Unit
    '*.ntb-apply-json-to-space': (_, newJson) ->
      try
        newDefs = JSON.parse(newJson)
      catch ex
        # coffeelint: disable=max_line_length
        messages = [
            "An error occurred when trying to read the given JSON for loading.  You can try to review the error and the data, fix any issues with it, and load again."
          , ex.message
        ]
        # coffeelint: enable=max_line_length
        @fire('ntb-errors', {}, messages, ex.stack)
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
      @showBlockForm(space.name, block, null, "Add New Block", "ntb-block-added", "Discard New Block")
      return

    # (Context, NetTangoBlock) => Unit
    '*.ntb-block-added': (_, block) ->
      space = @get('space')
      @push("space.defs.blocks", block)
      @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-show-edit-block-form': (_, blockIndex) ->
      space = @get('space')
      block = space.defs.blocks[blockIndex]
      @showBlockForm(space.name, block, blockIndex, "Update Block", "ntb-block-updated", "Discard Changes")
      return

    # (Context, NetTangoBlock, Integer) => Unit
    '*.ntb-block-updated': (_, block, blockIndex) ->
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
      @push("space.defs.blocks", copy)
      @updateNetTango(space, true)
      return

  }

  # (String, NetTangoBlock, Integer, String, String, String) => Unit
  showBlockForm: (spaceName, block, blockIndex, submitLabel, submitEvent, cancelLabel) ->
    form = @get('blockEditForm')
    form.show(this, spaceName, block, blockIndex, submitLabel, submitEvent, cancelLabel)
    overlay = @root.find('.widget-edit-form-overlay')
    overlay.classList.add('ntb-dialog-overlay')
    return

  # (NetTangoSpace | null) => String
  getNetTangoContainerId: (space) ->
    if not space then space = @get("space")
    "#{space.spaceId}-canvas"

  # (NetTangoSpace) => Unit
  initNetTango: (space) ->
    containerId            = @getNetTangoContainerId(space)
    space.defs.height      = space.height
    space.defs.width       = space.width
    space.defs.blockStyles = @get("blockStyles")

    try
      NetTango.restore("NetLogo", containerId, space.defs, NetTangoRewriter.formatDisplayAttribute)
    catch ex
      @handleNetTangoError(ex)
      return

    netTangoData = NetTango.save(containerId)
    @set("space.defs", netTangoData)
    @set("defsJson",   JSON.stringify(netTangoData, null, '  '))

    containerId = @getNetTangoContainerId(space)
    @setSpaceNetLogo(space, containerId)

    NetTango.onProgramChanged(containerId, (ntContainerId, event) =>
      if (@get('space')?)
        # `space` can change after we `render`, so do not use the one we already got above -JMB 11/2018
        s = @get('space')
        @handleNetTangoEvent(s, ntContainerId, event)
      return
    )
    return

  # (NetTangoSpace, String) => Unit
  setSpaceNetLogo: (space, containerId) ->
    space.netLogoCode    = NetTango.exportCode(containerId, NetTangoRewriter.formatCodeAttribute).trim()
    space.netLogoDisplay = NetTango.exportCode(containerId).trim()
    return

  # (NetTangoSpace, String, Event) => Unit
  handleNetTangoEvent: (space, containerId, event) ->
    space.defs.program.chains = NetTango.save(containerId).program.chains
    @setSpaceNetLogo(space, containerId)
    switch event.type

      when "block-changed"
        @saveNetTango()
        @fire('ntb-block-code-changed')
        @fire('ntb-space-changed')

      when "attribute-changed"
        @saveNetTango()
        setCode = NetTangoRewriter.formatSetAttribute(containerId, event.blockId, event.instanceId,
                      event.attributeId, event.formattedValue)
        @fire('ntb-run', setCode, @squelch)
        @fire('ntb-block-code-changed')
        @fire('ntb-space-changed')

      when "menu-item-clicked"
        playMode = @get("playMode")
        if (not playMode)
          space      = @get("space")
          blockIndex = space.defs.blocks.findIndex( (block) -> block.id is event.blockId )
          block      = space.defs.blocks[blockIndex]
          @showBlockForm(space.name, block, blockIndex, "Update Block", "ntb-block-updated", "Discard Changes")

      when "menu-item-context-menu"
        playMode = @get("playMode")
        if (not playMode)
          space      = @get("space")
          blockIndex = space.defs.blocks.findIndex( (block) -> block.id is event.blockId )
          block      = space.defs.blocks[blockIndex]
          spaces     = @parent.get("spaces")
          modifyMenu = @createModifyMenu(block, blockIndex, space, spaces)
          @get('popupMenu').popup(this, event.x, event.y, modifyMenu)

    return

  # (NetTangoSpace, Boolean) => Unit
  refreshNetTango: (space, keepOldChains) ->
    containerId = @getNetTangoContainerId(space)

    newChains = if (keepOldChains)
      NetTango.save(containerId).program.chains
    else
      space.defs.program.chains

    try
      NetTango.restore("NetLogo", containerId, {
        version:     space.defs.version,
        height:      space.height,
        width:       space.width,
        blockStyles: @get("blockStyles"),
        blocks:      space.defs.blocks,
        expressions: space.defs.expressions,
        program:     { chains: newChains }
      }, NetTangoRewriter.formatDisplayAttribute)
    catch ex
      @handleNetTangoError(ex)
      return

    @saveNetTango(containerId)
    @setSpaceNetLogo(space, containerId)
    return

  # (String|null) => Unit
  saveNetTango: (containerId) ->
    if not containerId then containerId = @getNetTangoContainerId()
    netTangoData = NetTango.save(containerId)
    @set("space.defs", netTangoData)
    @set("defsJson",   JSON.stringify(netTangoData, null, '  '))
    return

  # (NetTangoSpace, Boolean) => Unit
  updateNetTango: (space, keepOldChains) ->
    @refreshNetTango(space, keepOldChains)

    @fire('ntb-block-code-changed')
    @fire('ntb-run', {}, NetTangoRewriter.createSpaceVariables(space).join(" "))
    if keepOldChains then @fire('ntb-space-changed')
    return

  # (Exception) => Unit
  handleNetTangoError: (ex) ->
    # coffeelint: disable=max_line_length
    messages = [
        "An error occurred setting up a NetTango workspace.  If this happened during normal use, then this is a bug.  If this happened while trying to load workspaces, the workspace data may have been improperly modified in some way.  See the error message for more information."
      , ex.message
    ]
    # coffeelint: enable=max_line_length
    if ex.dartException?.source? then messages.push(ex.dartException.source.message)
    @fire('ntb-errors', {}, messages, ex.stack)
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

  # (Exception) => Unit
  squelch: (error) ->
    console.log(error)
    return

  components: {
    jsonEditor: RactiveJsonEditor
    labeledInput: RactiveTwoWayLabeledInput
  }

  template:
    # coffeelint: disable=max_line_length
    """
    {{# space }}

    <div class="ntb-block-def">

      <div class="ntb-space-title-bar" >

        <input type="text" class="ntb-space-title" value="{{ name }}"{{# playMode }} readOnly{{/}} on-change="ntb-space-title-changed">

        <button id="recompile-{{ spaceId }}" class="ntb-button" type="button" on-click="ntb-recompile-start"{{# !codeIsDirty }} disabled{{/}}>Recompile</button>

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
