window.RactiveNetTangoDefs = Ractive.extend({
  on: {
    'init': (_) ->
      at = @
      document.addEventListener('click', (event) ->
        if event?.button isnt 2
          at.set('contextMenu.show', false)
        return
      )

    '*.ntb-delete-blockspace': (_, spaceNumber) ->
      @splice('spaces', spaceNumber, 1)
      return

    'ntb-show-block-defaults': (_, spaceNumber) ->
      NetTangoBlockDefaults.blocks.event = 'ntb-create-block'
      menu = @findComponent('popupmenu')
      menu.set('content', NetTangoBlockDefaults.blocks)
      @set('contextMenu.buttonId', "add-block-button-#{spaceNumber}")
      @set('contextMenu.tag', spaceNumber)
      @set('contextMenu.show', true)
      return false

    'ntb-show-block-modify': (_, spaceNumber) ->
      menu = @findComponent('popupmenu')
      modifyMenu = @createModifyMenuContent(spaceNumber)
      menu.set('content', modifyMenu)
      @set('contextMenu.buttonId', "modify-block-button-#{spaceNumber}")
      @set('contextMenu.tag', spaceNumber)
      @set('contextMenu.show', true)
      return false

    '*.ntb-delete-block': (_, spaceNumber, blockNumber) ->
      space = @get('spaces')[spaceNumber]
      space.defs.blocks.splice(blockNumber, 1)
      @set("spaces[#{spaceNumber}].defsJson", JSON.stringify(space.defs, null, '  '))
      @initNetTangoForSpace(space)
      return

    'ntb-confirm-delete': (_, spaceNumber) ->
      menu = @findComponent('popupmenu')
      menu.set('content', {
        sureCheck: {
          , name: 'Are you sure?'
          , items: [
            { action: 'Yes, delete block space', event: 'ntb-delete-blockspace' }
          ]
        }
      })
      @set('contextMenu.buttonId', "delete-space-button-#{spaceNumber}")
      @set('contextMenu.tag', spaceNumber)
      @set('contextMenu.show', true)
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
    # Not a huge fan of this, but the Ractive data binding isn't doing the job and NetTango resets the sizes on each init.
    canvas = document.getElementById(ntId)
    canvas.height = space.height * 2
    canvas.width = space.width * 2
    canvas.style = "height: #{space.height}px; width: #{space.width}px"
    NetTango.init(ntId, space.defs)
    return

  createModifyMenuContent: (spaceNumber) ->
    content = []
    space = @get('spaces')[spaceNumber]
    dele = { event: 'ntb-delete-block', action: 'delete' }
    edit = { event: 'ntb-edit-block', action: 'edit' }
    for def, num in space.defs.blocks
      key = "block#{num}"
      content.push({
        name:  def.action
        items: [dele, edit]
      })
    content

  createSpace: (spaceVals) ->
    spaces  = @get('spaces')
    id      = @get('nextId')
    spaceId = "ntb-defs-#{id}"
    defs    = if spaceVals.defs? then spaceVals.defs else { blocks: [] }
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
    confirmDelete:      false,
    contextMenu:        {
      , show:     false
      , content:  undefined
      , buttonId: undefined
      , tag:      undefined
    }
  }

  components: {
    popupmenu: RactivePopupMenu
  }

  template:
    """
    <popupmenu visible="{{contextMenu.show}}" elementId="{{contextMenu.buttonId}}" tag="{{contextMenu.tag}}" />
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
})
