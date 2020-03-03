dele = { eventName: 'ntb-delete-block',         name: 'delete' }
edit = { eventName: 'ntb-show-edit-block-form', name: 'edit' }
up   = { eventName: 'ntb-block-up',             name: 'move up' }
dn   = { eventName: 'ntb-block-down',           name: 'move down' }
dup  = { eventName: 'ntb-duplicate-block',      name: 'duplicate' }

modifyBlockMenuItems = [dele, edit, up, dn, dup]

window.RactiveSpace = Ractive.extend({

  data: () -> {
    playMode:      false, # Boolean
    codeIsDirty:   false, # Boolean
    space:         null,  # NetTangoSpace
    netLogoCode:   "",    # String
    blockEditForm: null,  # RactiveBlockForm
    confirmDialog: null,  # RactiveConfirmDialog
    showJson:      false, # Boolean
    popupMenu:     null   # RactivePopupMenu
    blockStyles:   null   # Object
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
      modifyMenu = @createModifyMenuContent(space)
      @get('popupMenu').popup(this, pageX, pageY, modifyMenu)
      return false

    # (Context, Integer) => Unit
    '*.ntb-delete-block': (_, blockNumber) ->
      space = @get('space')
      @splice("space.defs.blocks", blockNumber, 1)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space, true)
      return

    # (Context, NetTangoSpace) => Unit
    'ntb-apply-json-to-space': (_, space) ->
      try
        newDefs = JSON.parse(space.defsJson)
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
      @updateNetTango(space, false)
      return

    # (Context, NetTangoSpace) => Unit
    'ntb-space-json-change': (_, space) ->
      oldDefsJson = JSON.stringify(space.defs, null, '  ')
      if (oldDefsJson isnt space.defsJson)
        @set("space.defsJsonChanged", true)
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
      @showBlockForm(space.name, block, null, "Add New Block", "ntb-block-added")
      return

    # (Context, NetTangoBlock) => Unit
    '*.ntb-block-added': (_, block) ->
      space = @get('space')
      @push("space.defs.blocks", block)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-show-edit-block-form': (_, blockNumber) ->
      space = @get('space')
      block = space.defs.blocks[blockNumber]
      @showBlockForm(space.name, block, blockNumber, "Update Block", "ntb-block-updated")
      return

    # (Context, NetTangoBlock, Integer) => Unit
    '*.ntb-block-updated': (_, block, blockNumber) ->
      space = @get('space')
      space.defs.blocks[blockNumber] = block
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-block-up': (_, blockNumber) ->
      space = @get('space')
      if (blockNumber > 0)
        swap = space.defs.blocks[blockNumber - 1]
        space.defs.blocks[blockNumber - 1] = space.defs.blocks[blockNumber]
        space.defs.blocks[blockNumber] = swap
        @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
        @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-block-down': (_, blockNumber) ->
      space = @get('space')
      if (blockNumber < (space.defs.blocks.length - 1))
        swap = space.defs.blocks[blockNumber + 1]
        space.defs.blocks[blockNumber + 1] = space.defs.blocks[blockNumber]
        space.defs.blocks[blockNumber] = swap
        @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
        @updateNetTango(space, true)
      return

    # (Context, Integer) => Unit
    '*.ntb-duplicate-block': (_, blockNumber) ->
      space    = @get('space')
      original = space.defs.blocks[blockNumber]
      copy = NetTangoBlockDefaults.copyBlock(original)
      @push("space.defs.blocks", copy)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space, true)
      return

  }

  # (String, NetTangoBlock, Integer, String, String) => Unit
  showBlockForm: (spaceName, block, blockNumber, submitLabel, submitEvent) ->
    form = @get('blockEditForm')
    form.show(this, spaceName, block, blockNumber, submitLabel, submitEvent)
    overlay = @root.find('.widget-edit-form-overlay')
    overlay.classList.add('ntb-dialog-overlay')
    return

  getNetTangoContainerId: (space) ->
    "#{space.spaceId}-canvas"

  # (NetTangoSpace) => Unit
  initNetTango: (space) ->
    containerId            = @getNetTangoContainerId(space)
    space.defs.height      = space.height
    space.defs.width       = space.width
    space.defs.blockStyles = @get("blockStyles")

    try
      NetTango.init("NetLogo", containerId, space.defs, NetTangoRewriter.formatDisplayAttribute)
    catch ex
      @handleNetTangoError(ex)
      return

    netTangoData = NetTango.save(containerId)
    @set("space.defs",     netTangoData)
    @set("space.defsJson", JSON.stringify(netTangoData, null, '  '))

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

  setSpaceNetLogo: (space, containerId) ->
    space.netLogoCode    = NetTango.exportCode(containerId, NetTangoRewriter.formatCodeAttribute).trim()
    space.netLogoDisplay = NetTango.exportCode(containerId).trim()

  handleNetTangoEvent: (space, containerId, event) ->
    space.defs.program.chains = NetTango.save(containerId).program.chains
    @setSpaceNetLogo(space, containerId)
    switch event.type

      when "block-changed"
        @fire('ntb-block-code-changed')
        @fire('ntb-space-changed')

      when "attribute-changed"
        setCode = NetTangoRewriter.formatSetAttribute(containerId, event.blockId, event.instanceId,
                                                      event.attributeId, event.value)
        @fire('ntb-run', setCode, @squelch)
        @fire('ntb-block-code-changed')
        @fire('ntb-space-changed')

      when "menu-item-clicked"
        playMode = @get("playMode")
        if (not playMode)
          space      = @get("space")
          blockIndex = space.defs.blocks.findIndex( (block) -> block.id is event.blockId )
          block      = space.defs.blocks[blockIndex]
          @showBlockForm(space.name, block, blockIndex, "Update Block", "ntb-block-updated")

      when "menu-item-context-menu"
        playMode = @get("playMode")
        if (not playMode)
          space      = @get("space")
          blockIndex = space.defs.blocks.findIndex( (block) -> block.id is event.blockId )
          block      = space.defs.blocks[blockIndex]
          modifyMenu = @createModifyMenu(block, blockIndex)
          @get('popupMenu').popup(this, event.x, event.y, modifyMenu)

    return

  # (NetTangoSpace) => Unit
  updateNetTango: (space, keepOldChains) ->
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

    netTangoData = NetTango.save(containerId)
    @set("space.defs",     netTangoData)
    @set("space.defsJson", JSON.stringify(netTangoData, null, '  '))
    @setSpaceNetLogo(space, containerId)

    @fire('ntb-block-code-changed')
    @fire('ntb-run', {}, NetTangoRewriter.createSpaceVariables(space).join(" "))
    if keepOldChains then @fire('ntb-space-changed')
    return

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

  # (NetTangoBlock) => Content
  createModifyMenu: (block, blockIndex) ->
    {
      name:  block.action
      items: modifyBlockMenuItems.map((x) -> Object.assign({ data: blockIndex }, x))
    }

  # (NetTangoSpace) => Content
  createModifyMenuContent: (space) ->
    items = for block, blockIndex in space.defs.blocks
      @createModifyMenu(block, blockIndex)

    {
      name: "_",
      items: items
    }

  clearBlockStyles: () ->
    space = @get('space')
    for block in space.defs.blocks
      for prop in [ 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
        if block.hasOwnProperty(prop)
          delete block[prop]
    @set('space', space)
    @updateNetTango(space, true)
    return

  squelch: (error) ->
    console.log(error)

  components: {
    labeledInput: RactiveTwoWayLabeledInput
  }

  template:
    # coffeelint: disable=max_line_length
    """
    {{# space }}
    <div class="ntb-block-def">
      <input type="text" class="ntb-block-space-name" value="{{ name }}"{{# playMode }} readOnly{{/}} on-change="ntb-space-title-changed">

      <div class="ntb-block-defs-controls" >
        <button id="recompile-{{ spaceId }}" class="ntb-button" type="button" on-click="ntb-recompile-start"{{# !codeIsDirty }} disabled{{/}}>Recompile</button>

        {{# !playMode }}
          <button id="add-block-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-show-block-defaults', this ]">Add Block ▼</button>
          <button id="modify-block-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-show-block-modify', this ]" {{# defs.blocks.length === 0 }}disabled{{/}}>Modify Block ▼</button>
          <button id="delete-space-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-confirm-delete', id ]" >Delete Block Space</button>
          <labeledInput id="width-{{ spaceId }}" name="width" type="number" value="{{ width }}" labelStr="Width"
            onChange="ntb-size-change" min="50" max="1600" divClass="ntb-flex-column" class="ntb-input" />
          <labeledInput id="height-{{ spaceId }}" name="height" type="number" value="{{ height }}" labelStr="Height"
            onChange="ntb-size-change" min="50" max="1600" divClass="ntb-flex-column" class="ntb-input" />
        {{/ !playMode }}

      </div>

      <div id="{{ spaceId }}" class="ntb-canvas" >
        <div id="{{ spaceId }}-canvas" />
      </div>

      {{# !playMode }}
      <div class="ntb-block-defs-controls">
        <label class="ntb-toggle-block" >
          <input id="info-toggle" type="checkbox" checked="{{ showJson }}" />
          <div>{{# showJson }}▲{{else}}▼{{/}} Block Definition JSON</div>
        </label>
        {{# showJson }}<button class="ntb-button" type="button" on-click="[ 'ntb-apply-json-to-space', this ]"{{# !defsJsonChanged }} disabled{{/}}>Apply JSON to Space</button>{{/ showJson }}
      </div>

      {{# showJson }}
      <textarea id="{{ spaceId }}-json" class="ntb-block-def-json" value="{{ defsJson }}" on-change-keyup-paste="[ 'ntb-space-json-change',
       this ]" />
      {{/ showJson }}
      {{/ !playMode }}
    </div>
    {{/ space }}
    """
    # coffeelint: enable=max_line_length
})
