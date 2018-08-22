window.RactiveNetTangoSpace = Ractive.extend({

  data: () -> {
    playMode:      false, # Boolean
    space:         null,  # NetTangoSpace
    netLogoCode:   "",    # String
    blockEditForm: null,  # RactiveNetTangoBlockForm
    showJson:      false, # Boolean
    popupMenu:     null   # RactivePopupMenu
  }

  on: {

    # (Context) => Unit
    'complete': (_) ->
      space = @get('space')
      @initNetTango(space)
      space.netLogoCode = NetTango.exportCode(space.spaceId + '-canvas', 'NetLogo')
      NetTango.onProgramChanged(space.spaceId + "-canvas", (ntCanvasId) =>
        space.netLogoCode = NetTango.exportCode(ntCanvasId, 'NetLogo').trim()
        @fire('ntb-code-change', {}, ntCanvasId, false)
        return
      )
      @fire('ntb-code-change', {}, space.spaceId + "-canvas", true)
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
      @updateNetTango(space)
      return

    # (Context, String) => Unit
    'ntb-code-change': (_, ntCanvasId) ->
      netTangoData = NetTango.save(ntCanvasId)
      @set('space.defs.program', netTangoData.program)
      return

    # (Context, Integer) => Boolean
    'ntb-confirm-delete': ({ event: { pageX, pageY } }, spaceNumber) ->
      delMenu = {
        name: "_"
        items: [
          {
            name: 'Are you sure?'
            , items: [
              { name: 'Yes, delete block space', eventName: 'ntb-delete-blockspace' }
            ]
          }
        ]
      }
      @get('popupMenu').popup(this, pageX, pageY, delMenu, spaceNumber)
      return false

    # (Context, NetTangoSpace) => Unit
    'ntb-apply-json-to-space': (_, space) ->
      newDefs = JSON.parse(space.defsJson)
      @set("space.defs", newDefs)
      @updateNetTango(space)
      return

    # (Context, NetTangoSpace) => Unit
    'ntb-space-json-change': (_, space) ->
      oldDefsJson = JSON.stringify(space.defs, null, '  ')
      if(oldDefsJson isnt space.defsJson)
        @set("space.defsJsonChanged", true)
      return

    # (Context) => Unit
    '*.ntb-size-change': (_) ->
      space = @get('space')
      @updateNetTango(space)
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
      @updateNetTango(space)
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
      @updateNetTango(space)
      return

    # (Context, Integer) => Unit
    '*.ntb-block-up': (_, blockNumber) ->
      space = @get('space')
      if (blockNumber > 0)
        swap = space.defs.blocks[blockNumber - 1]
        space.defs.blocks[blockNumber - 1] = space.defs.blocks[blockNumber]
        space.defs.blocks[blockNumber] = swap
        @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
        @updateNetTango(space)
      return

    # (Context, Integer) => Unit
    '*.ntb-block-down': (_, blockNumber) ->
      space = @get('space')
      if (blockNumber < (space.defs.blocks.length - 1))
        swap = space.defs.blocks[blockNumber + 1]
        space.defs.blocks[blockNumber + 1] = space.defs.blocks[blockNumber]
        space.defs.blocks[blockNumber] = swap
        @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
        @updateNetTango(space)
      return

  }

  # (String, NetTangoBlock, Integer, String, String) => Unit
  showBlockForm: (spaceName, block, blockNumber, submitLabel, submitEvent) ->
    form = @get('blockEditForm')
    form.show(this, spaceName, block, blockNumber, submitLabel, submitEvent)
    overlay = @root.find('.widget-edit-form-overlay')
    overlay.style.height   = "100%"
    overlay.style.width    = "100%"
    overlay.style.top      = 0
    overlay.style.left     = 0
    overlay.style.position = "absolute"
    overlay.style.display  = "block"
    return

  # (NetTangoSpace) => Unit
  initNetTango: (space) ->
    ntId = space.spaceId + "-canvas"
    canvas = @find("##{ntId}")
    canvas.height = space.height
    canvas.width = space.width
    NetTango.init(ntId, space.defs)
    return

  # (NetTangoSpace) => Unit
  updateNetTango: (space) ->
    ntId = space.spaceId + "-canvas"
    canvas = @find("##{ntId}")
    canvas.height = space.height
    canvas.width = space.width
    old = NetTango.save(ntId)
    # NetTango includes "empty" procedures as code with the save, but those cause ghost blocks when we change things
    # and reload, so we clear them out
    newChains = old.program.chains.filter((ch) -> ch.length > 1)
    NetTango.restore(ntId, {
      blocks:      space.defs.blocks,
      expressions: space.defs.expressions,
      program:     { chains: newChains }
    })
    space.netLogoCode = NetTango.exportCode(space.spaceId + '-canvas', 'NetLogo')
    @fire('ntb-code-change', {}, space.spaceId + "-canvas", false)
    return

  # (NetTangoSpace) => Content
  createModifyMenuContent: (space) ->
    dele = { eventName: 'ntb-delete-block', name: 'delete' }
    edit = { eventName: 'ntb-show-edit-block-form', name: 'edit' }
    up = { eventName: 'ntb-block-up', name: 'move up' }
    dn = { eventName: 'ntb-block-down', name: 'move down' }
    items = for def, num in space.defs.blocks
      itemDele = Object.assign({ data: num }, dele)
      itemEdit = Object.assign({ data: num }, edit)
      itemUp   = Object.assign({ data: num }, up)
      itemDn   = Object.assign({ data: num }, dn)
      {
        name:  def.action
        items: [itemDele, itemEdit, itemUp, itemDn]
      }
    {
      name: "_",
      items: items
    }

  components: {
    labelledInput: RactiveLabelledInput
  }

  template:
    # coffeelint: disable=max_line_length
    """
    {{# space }}
    <div class="ntb-block-def">
      <input type="text" class="ntb-block-space-name" value="{{ name }}"{{# playMode }} readOnly{{/}} on-change="ntb-code-change">

      {{# !playMode }}
      <div class="ntb-block-defs-controls" >
        <button id="add-block-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-show-block-defaults', this ]">Add Block ▼</button>
        <button id="modify-block-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-show-block-modify', this ]" {{# defs.blocks.length === 0 }}disabled{{/}}>Modify Block ▼</button>
        <button id="delete-space-button-{{ spaceId }}" class="ntb-button" type="button" on-click="[ 'ntb-confirm-delete', id ]" >Delete Block Space</button>
        <labelledInput id="width-{{ spaceId }}" name="width" type="number" value="{{ width }}" label="Width" onChange="ntb-size-change" min="50" max="1600" />
        <labelledInput id="height-{{ spaceId }}" name="height" type="number" value="{{ height }}" label="Height" onChange="ntb-size-change" min="50" max="1600" />
      </div>
      {{/ !playMode }}

      <div class="nt-container" id="{{ spaceId }}" >
        <canvas id="{{ spaceId }}-canvas" class="nt-canvas" />
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
       this ]" lazy />
      {{/ showJson }}
      {{/ !playMode }}
    </div>
    {{/ space }}
    """
    # coffeelint: enable=max_line_length
})
