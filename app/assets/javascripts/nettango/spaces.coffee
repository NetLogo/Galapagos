window.RactiveSpaces = Ractive.extend({

  data: () -> {
    blockEditForm:    null      # RactiveBlockForm
    blockStyles:      undefined # NetTangoBlockStyles
    codeIsDirty:      false     # Boolean
    confirmDialog:    null      # RactiveConfirmDialog
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
      blockEditForm = @findComponent('blockEditForm')
      @set('blockEditForm', blockEditForm)
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
    '*.ntb-confirm-delete': (_, spaceNumber) ->
      @get('confirmDialog').show({
        text:    "Do you want to delete this workspace?",
        approve: { text: "Yes, delete the workspace", event: "ntb-delete-blockspace" },
        deny:    { text: "No, keep workspace" },
        eventArguments: [ spaceNumber ],
        eventTarget:    this
      })
      return false

    # (Context, Integer) => Unit
    '*.ntb-delete-blockspace': (_, spaceNumber) ->
      spaces = @get('spaces')
      newSpaces = spaces.filter( (s) -> s.id isnt spaceNumber )
      newSpaces.forEach( (s, i) ->
        s.id      = i
        s.spaceId = "ntb-defs-#{i}"
      )
      @set('spaces', newSpaces)
      @updateCode()
      @fire('ntb-space-changed')
      return

    # (Context) => Unit
    '*.ntb-recompile-start': (_) ->
      @recompile()
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
    codeWasDirty = @get('codeIsDirty')
    newCode      = @assembleCode(displayOnly = false)
    codeChanged  = lastCode isnt newCode
    @set('codeIsDirty', codeWasDirty or codeChanged)
    @set('code', @assembleCode(displayOnly = true))
    if codeChanged
      @set('lastCode', newCode)
      @fire('ntb-code-dirty')
    return

  # () => Unit
  recompile: () ->
    ntbCode = @assembleCode(displayOnly = false)
    @fire('ntb-recompile', ntbCode)
    @set('lastCode', ntbCode)
    @set('codeIsDirty', false)
    return

  # () => Unit
  assembleCode: (displayOnly) ->
    spaces = @get('spaces')
    spaceCodes =
      spaces.map( (space) ->
        if displayOnly
          "; Code for #{space.name}\n#{space.netLogoDisplay ? ""}".trim()
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
    defs.expressions = defs.expressions ? NetTangoBlockDefaults.expressions
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
    blockEditForm: RactiveBlockForm
    codeMirror:    RactiveCodeMirror
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <blockEditForm
      idBasis="ntb-block"
      parentClass="ntb-builder"
      verticalOffset="10"
      blockStyles={{ blockStyles }}
      allTags={{ allTags }}
    />

    <div class="ntb-block-defs-list">
      {{#spaces:spaceNum }}
        <tangoSpace
          space="{{ this }}"
          playMode="{{ playMode }}"
          popupMenu="{{ popupMenu }}"
          confirmDialog="{{ confirmDialog }}"
          blockEditForm="{{ blockEditForm }}"
          codeIsDirty="{{ codeIsDirty }}"
          blockStyles="{{ blockStyles }}"
        />
      {{/spaces }}
    </div>

    {{#if showCode }}
    <label for="ntb-code">NetLogo Code</label>
    <codeMirror
      id="ntb-code"
      mode="netlogo"
      code="{{ code }}"
      config="{ readOnly: 'nocursor' }"
      extraClasses="[ 'ntb-code', 'ntb-code-large', 'ntb-code-readonly' ]"
    />
    {{/if showCode }}
    """
    # coffeelint: enable=max_line_length
})
