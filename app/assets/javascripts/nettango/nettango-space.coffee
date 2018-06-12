window.RactiveNetTangoSpace = Ractive.extend({
  on: {

    'complete': (_) ->
      space = @get('space')
      @initNetTangoForSpace(space)
      at = @
      NetTango.onProgramChanged(space.spaceId + "-canvas", (id) ->
        at.fire('ntb-code-change')
        return
      )
      return

    'ntb-show-block-defaults': ({ event: { pageX, pageY } }, space) ->
      NetTangoBlockDefaults.blocks.eventName = 'ntb-show-create-block-form'
      @get('popupmenu').popup(@, pageX, pageY, NetTangoBlockDefaults.blocks, space.id)
      return false

    'ntb-show-block-modify': ({ event: { pageX, pageY } }, space) ->
      modifyMenu = @createModifyMenuContent(space)
      @get('popupmenu').popup(@, pageX, pageY, modifyMenu, space.id)
      return false

    '*.ntb-delete-block': (_, spaceNumber, blockNumber) ->
      space = @get('space')
      space.defs.blocks.splice(blockNumber, 1)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @initNetTangoForSpace(space)
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
      return false

    'ntb-apply-json-to-space': (_, space) ->
      newDefs = JSON.parse(space.defsJson)
      @set("spaces[#{number}].defs", newDefs)
      @initNetTangoForSpace(space)
      return

    'ntb-space-json-change': (_, space) ->
      oldDefsJson = JSON.stringify(space.defs, null, '  ')
      if(oldDefsJson != space.defsJson)
        @set("spaces[#{number}].defsJsonChanged", true)
      return

    '*.ntb-size-change': (_) ->
      space = @get('space')
      @initNetTangoForSpace(space)
      return

    '*.ntb-show-create-block-form': (_, spaceNumber, blockBase) ->
      space = @get('space')
      block = NetTangoBlockDefaults.copyBlock(blockBase)
      @showBlockForm(space.name, spaceNumber, block, null, "Add New Block", "ntb-block-added")
      return

    '*.ntb-block-added': (_, spaceNumber, block) ->
      space = @get('space')
      space.defs.blocks.push(block)
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @initNetTangoForSpace(space)
      return

    '*.ntb-show-edit-block-form': (_, spaceNumber, blockNumber) ->
      space = @get('space')
      block = space.defs.blocks[blockNumber]
      @showBlockForm(space.name, spaceNumber, block, blockNumber, "Update Block", "ntb-block-updated")
      return

    '*.ntb-block-updated': (_, spaceNumber, block, blockNumber) ->
      space = @get('space')
      space.defs.blocks[blockNumber] = block
      @set("space.defsJson", JSON.stringify(space.defs, null, '  '))
      @initNetTangoForSpace(space)
      return

  }

  showBlockForm: (spaceName, spaceNumber, block, blockNumber, submitLabel, submitEvent) ->
    form = @get('blockEditForm')
    form.show(@, spaceName, spaceNumber, block, blockNumber, submitLabel, submitEvent)
    overlay = document.querySelector('.widget-edit-form-overlay')
    overlay.style.height   = "100%"
    overlay.style.width    = "100%"
    overlay.style.top      = 0
    overlay.style.left     = 0
    overlay.style.position = "absolute"
    overlay.style.display  = "block"
    return

  initNetTangoForSpace: (space) ->
    ntId = space.spaceId + "-canvas"
    # Not a huge fan of this, but the Ractive data binding isn't doing the job and NetTango resets the sizes each init.
    canvas = document.getElementById(ntId)
    canvas.height = space.height
    canvas.width = space.width
    NetTango.init(ntId, space.defs)
    return

  createModifyMenuContent: (space) ->
    dele = { eventName: 'ntb-delete-block', name: 'delete' }
    edit = { eventName: 'ntb-show-edit-block-form', name: 'edit' }
    items = for def, num in space.defs.blocks
      itemDele = Object.assign({ data: num }, dele)
      itemEdit = Object.assign({ data: num }, edit)
      {
        name:  def.action
        items: [itemDele, itemEdit]
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
    space:         [],
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
