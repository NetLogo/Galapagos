window.RactiveNetTangoSpace = Ractive.extend({
  on: {

    'complete': (_) ->
      space = @get('space')
      @initNetTango(space)
      space.netLogoCode = NetTango.exportCode(space.spaceId + '-canvas', 'NetLogo')
      at = @
      NetTango.onProgramChanged(space.spaceId + "-canvas", (ntCanvasId) ->
        space.netLogoCode = NetTango.exportCode(ntCanvasId, 'NetLogo').trim()
        at.fire('ntb-code-change', {}, ntCanvasId, false)
        return
      )
      @fire('ntb-code-change', {}, space.spaceId + "-canvas", true)
      return

    'ntb-show-block-defaults': ({ event: { pageX, pageY } }, space) ->
      NetTangoBlockDefaults.blocks.eventName = 'ntb-show-create-block-form'
      @get('popupmenu').popup(@, pageX, pageY, NetTangoBlockDefaults.blocks)
      return false

    'ntb-show-block-modify': ({ event: { pageX, pageY } }, space) ->
      modifyMenu = @createModifyMenuContent(space)
      @get('popupmenu').popup(@, pageX, pageY, modifyMenu)
      return false

    '*.ntb-delete-block': (_, blockNumber) ->
      space = @get('space')
      space.defs.blocks.splice(blockNumber, 1)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space)
      return

    'ntb-code-change': (_, ntCanvasId) ->
      netTangoData = NetTango.save(ntCanvasId)
      @set('space.defs.program', netTangoData.program)
      return

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
      @get('popupmenu').popup(@, pageX, pageY, delMenu, spaceNumber)
      return

    'ntb-apply-json-to-space': (_, space) ->
      newDefs = JSON.parse(space.defsJson)
      @set("space.defs", newDefs)
      @updateNetTango(space)
      return

    'ntb-space-json-change': (_, space) ->
      oldDefsJson = JSON.stringify(space.defs, null, '  ')
      if(oldDefsJson isnt space.defsJson)
        @set("space.defsJsonChanged", true)
      return

    '*.ntb-size-change': (_) ->
      space = @get('space')
      @updateNetTango(space)
      return

    '*.ntb-show-create-block-form': (_, blockBase) ->
      space = @get('space')
      block = NetTangoBlockDefaults.copyBlock(blockBase)
      @showBlockForm(space.name, block, null, "Add New Block", "ntb-block-added")
      return

    '*.ntb-block-added': (_, block) ->
      space = @get('space')
      space.defs.blocks.push(block)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space)
      return

    '*.ntb-show-edit-block-form': (_, blockNumber) ->
      space = @get('space')
      block = space.defs.blocks[blockNumber]
      @showBlockForm(space.name, block, blockNumber, "Update Block", "ntb-block-updated")
      return

    '*.ntb-block-updated': (_, block, blockNumber) ->
      space = @get('space')
      space.defs.blocks[blockNumber] = block
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @updateNetTango(space)
      return

    '*.ntb-block-up': (_, blockNumber) ->
      space = @get('space')
      if (blockNumber > 0)
        swap = space.defs.blocks[blockNumber - 1]
        space.defs.blocks[blockNumber - 1] = space.defs.blocks[blockNumber]
        space.defs.blocks[blockNumber] = swap
        @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
        @updateNetTango(space)
      return

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

  showBlockForm: (spaceName, block, blockNumber, submitLabel, submitEvent) ->
    form = @get('blockEditForm')
    form.show(@, spaceName, block, blockNumber, submitLabel, submitEvent)
    overlay = document.querySelector('.widget-edit-form-overlay')
    overlay.style.height   = "100%"
    overlay.style.width    = "100%"
    overlay.style.top      = 0
    overlay.style.left     = 0
    overlay.style.position = "absolute"
    overlay.style.display  = "block"
    return

  initNetTango: (space) ->
    ntId = space.spaceId + "-canvas"
    canvas = document.getElementById(ntId)
    canvas.height = space.height
    canvas.width = space.width
    NetTango.init(ntId, space.defs)
    return

  updateNetTango: (space) ->
    ntId = space.spaceId + "-canvas"
    canvas = document.getElementById(ntId)
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
    return

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

  expressionDefaults: () ->
    return [
      { name: "true",  type: "bool" },
      { name: "false", type: "bool" },
      { name: "AND",   type: "bool", arguments: [ "bool", "bool"],  format: "({0} and {1})" },
      { name: "OR",    type: "bool", arguments: [ "bool", "bool" ], format: "({0} or {1})" },
      { name: "NOT",   type: "bool", arguments: [ "bool"],          format: "(not {0})" },
      { name: ">",     type: "bool", arguments: [ "num", "num" ] },
      { name: ">=",    type: "bool", arguments: [ "num", "num" ] },
      { name: "<",     type: "bool", arguments: [ "num", "num" ] },
      { name: "<=",    type: "bool", arguments: [ "num", "num" ] },
      { name: "!=",    type: "bool", arguments: [ "num", "num" ] },
      { name: "=",     type: "bool", arguments: [ "num", "num" ] },
      { name: "+",     type: "num",  arguments: [ "num", "num"] },
      { name: "-",     type: "num",  arguments: [ "num", "num"] },
      { name: "×",     type: "num",  arguments: [ "num", "num"], format: "({0} * {1})" },
      { name: "/",     type: "num",  arguments: [ "num", "num"] },
      { name: "random", type: "num", arguments: [ "num" ], format: "random-float {0}" }
    ]

  data: () -> {
    playMode:      false,
    space:         null,
    netLogoCode:   "",
    blockEditForm: null
  }

  components: {
    labelledInput: RactiveLabelledInput
  }

  template:
    # coffeelint: disable=max_line_length
    """{{#space }}
    <div class="ntb-block-def">
      <input type="text" class="ntb-block-space-name" value="{{ name }}"{{# playMode }} readOnly{{/}} on-change="ntb-code-change">
      {{# !playMode }}
      <div class="ntb-block-defs-controls" >
        <button id="add-block-button-{{ spaceId }}" class="ntb-button" on-click="[ 'ntb-show-block-defaults', this ]">Add Block ▼</button>
        <button id="modify-block-button-{{ spaceId }}" class="ntb-button" on-click="[ 'ntb-show-block-modify', this ]">Modify Block ▼</button>
        <button id="delete-space-button-{{ spaceId }}" class="ntb-button" on-click="[ 'ntb-confirm-delete', id ]" >Delete Block Space</button>
        <labelledInput id="width-{{ spaceId }}" name="width" type="number" value="{{ width }}" label="Width" onChange="ntb-size-change" min="50" max="1600" />
        <labelledInput id="height-{{ spaceId }}" name="height" type="number" value="{{ height }}" label="Height" onChange="ntb-size-change" min="50" max="1600" />
      </div>
      {{/}}
      <div class="nt-container" id="{{ spaceId }}" >
        <canvas id="{{ spaceId }}-canvas" class="nt-canvas" />
      </div>
      {{# !playMode }}
      <div class="ntb-block-defs-controls">
        <label for="{{ spaceId }}-json">Block Definition JSON</label>
        <button class="ntb-button" on-click="[ 'ntb-apply-json-to-space', this ]"{{# !defsJsonChanged }} disabled{{/}}>Apply JSON to Space</button>
      </div>
      <textarea id="{{ spaceId }}-json" class="ntb-block-def-json" value="{{ defsJson }}" on-change-keyup-paste="[ 'ntb-space-json-change', this ]" lazy />
      {{/}}
    </div>
    {{/}}"""
    # coffeelint: enable=max_line_length
})
