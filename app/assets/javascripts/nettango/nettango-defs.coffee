window.RactiveNetTangoDefs = Ractive.extend({
  on: {

    '*.ntb-delete-blockspace': (_, spaceNumber) ->
      @splice('spaces', spaceNumber, 1)
      return

    'ntb-show-block-defaults': ({ event: { pageX, pageY } }, spaceNumber) ->
      NetTangoBlockDefaults.blocks.eventName = 'ntb-create-block'
      @popupmenu.popup(@, pageX, pageY, NetTangoBlockDefaults.blocks, spaceNumber)
      return false

    'ntb-show-block-modify': ({ event: { pageX, pageY } }, spaceNumber) ->
      modifyMenu = @createModifyMenuContent(spaceNumber)
      @popupmenu.popup(@, pageX, pageY, modifyMenu, spaceNumber)
      return false

    '*.ntb-delete-block': (_, spaceNumber, blockNumber) ->
      space = @get('spaces')[spaceNumber]
      space.defs.blocks.splice(blockNumber, 1)
      @set("spaces[#{spaceNumber}].defsJson", JSON.stringify(space.defs, null, '  '))
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
      @popupmenu.popup(@, pageX, pageY, delMenu, spaceNumber)
      return false

    'ntb-code-change': (_) ->
      lastCode    = @get('lastCode')
      newCode     = @assembleCode()
      codeIsDirty = lastCode != newCode
      @set('codeIsDirty', codeIsDirty)
      @set('code', newCode)
      if codeIsDirty
        @fire('ntb-code-dirty')
      return

    'ntb-apply-json-to-space': (_, space, number) ->
      newDefs = JSON.parse(space.defsJson)
      @set("spaces[#{number}].defs", newDefs)
      @initNetTangoForSpace(space)
      return

    'ntb-space-json-change': (_, space, number) ->
      oldDefsJson = JSON.stringify(space.defs, null, '  ')
      if(oldDefsJson != space.defsJson)
        @set("spaces[#{number}].defsJsonChanged", true)
      return
  }

  recompile: () ->
    ntbCode = @assembleCode()
    @fire('ntb-recompile', ntbCode)
    @set('lastCode', ntbCode)
    @set('codeIsDirty', false)
    return

  assembleCode: () ->
    spaces = @get('spaces')
    spaceCodes = for space, _ in spaces
      "; Code for #{space.name}\n#{NetTango.exportCode(space.spaceId + '-canvas', 'NetLogo')}".trim()
    spaceCodes.join("\n\n")

  addBlockToSpace: (spaceNumber, block) ->
    spaces = @get('spaces')
    space = spaces[spaceNumber]
    if(not space?) then console.error('ah geeze')
    space.defs.blocks.push(block)
    @set("spaces[#{spaceNumber}].defsJson", JSON.stringify(space.defs, null, '  '))
    @initNetTangoForSpace(space)
    return

  updateBlock: (spaceNumber, blockNumber, block) ->
    spaces = @get('spaces')
    space = spaces[spaceNumber]
    if(not space?) then console.error('ah geeze')
    space.defs.blocks[blockNumber] = block
    @set("spaces[#{spaceNumber}].defsJson", JSON.stringify(space.defs, null, '  '))
    @initNetTangoForSpace(space)
    return

  initNetTangoForSpace: (space) ->
    ntId = space.spaceId + "-canvas"
    # Not a huge fan of this, but the Ractive data binding isn't doing the job and NetTango resets the sizes each init.
    canvas = document.getElementById(ntId)
    canvas.height = space.height * 2
    canvas.width = space.width * 2
    canvas.style = "height: #{space.height}px; width: #{space.width}px"
    NetTango.init(ntId, space.defs)
    return

  createModifyMenuContent: (spaceNumber) ->
    space = @get('spaces')[spaceNumber]
    dele = { eventName: 'ntb-delete-block', name: 'delete' }
    edit = { eventName: 'ntb-edit-block', name: 'edit' }
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

  createSpace: (spaceVals) ->
    spaces  = @get('spaces')
    id      = @get('nextId')
    spaceId = "ntb-defs-#{id}"
    defs    = if spaceVals.defs? then spaceVals.defs else { blocks: [] }
    defs.expressions = defs.expressions ? @expressionDefaults()
    space = {
        id:                id
      , spaceId:           spaceId
      , name:              "Block Space #{id}"
      , width:             215
      , height:            250
      , defs:              defs
      , defsJson:          JSON.stringify(defs, null, '  ')
      , defsJsonChanged:   false
    }
    for propName in [ 'name', 'width', 'height' ]
      if(spaceVals.hasOwnProperty(propName))
        space[propName] = spaceVals[propName]

    @push('spaces', space)
    @set('nextId', id + 1)
    ntId = spaceId + "-canvas"
    NetTango.init(ntId, defs)
    at = @
    NetTango.onProgramChanged(ntId, (id) ->
      at.fire('ntb-code-change')
      return
    )
    return space

  data: () -> {
    playMode:           false,
    nextId:             0,
    spaces:             [],
    lastCompiledCode:   "",
    codeIsDirty:        false,
    confirmDelete:      false
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-block-defs-list">
      {{#spaces:spaceNum }}
        <div class="ntb-block-def">
          <input type="text" class="ntb-block-space-name" value="{{ name }}"{{# playMode }} readOnly{{/}} on-change="ntb-code-change">
          {{# !playMode }}
          <div class="ntb-block-defs-controls" >
            <button id="add-block-button-{{spaceNum}}" class="ntb-button" on-click="[ 'ntb-show-block-defaults', spaceNum ]">Add Block ▼</button>
            <button id="modify-block-button-{{spaceNum}}" class="ntb-button" on-click="[ 'ntb-show-block-modify', spaceNum ]">Modify Block ▼</button>
            <button id="delete-space-button-{{spaceNum}}" class="ntb-button" on-click="[ 'ntb-confirm-delete', spaceNum ]" >Delete Block Space</button>
          </div>
          {{/}}
          <div class="nt-container" id="{{ spaceId }}" >
            <canvas class="nt-canvas" height="{{ 2 * height }}" width="{{ 2 * width }}" style="height: {{ height }}px;width: {{ width }}px;" id="{{ spaceId }}-canvas" />
          </div>
          {{# !playMode }}
          <div class="ntb-block-defs-controls">
            <label for="{{ spaceId }}-json">Block Definition JSON</label>
            <button class="ntb-button" on-click="[ 'ntb-apply-json-to-space', this, spaceNum ]"{{# !defsJsonChanged }} disabled{{/}}>Apply JSON to Space</button>
          </div>
          <textarea id="{{ spaceId }}-json" class="ntb-block-def-json" value="{{ defsJson }}" on-change-keyup-paste="[ 'ntb-space-json-change', this, spaceNum ]" lazy />
          {{/}}
        </div>
      {{/spaces }}
    </div>
    <label for="ntb-code">NetLogo Code</label>
    <textarea id="ntb-code" readOnly>{{ code }}</textarea>
    """
    # coffeelint: enable=max_line_length
})
