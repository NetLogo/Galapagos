window.RactiveNetTangoDefs = Ractive.extend({
  on: {

    'complete': (_) ->
      blockEditForm = @findComponent('blockEditForm')
      @set('blockEditForm', blockEditForm)

    '*.ntb-code-change': (_) ->
      @updateCode()

    '*.ntb-delete-blockspace': (_, spaceNumber) ->
      @splice('spaces', spaceNumber, 1)
      return

  }

  updateCode: () ->
    lastCode    = @get('lastCode')
    newCode     = @assembleCode()
    codeIsDirty = lastCode isnt newCode
    @set('codeIsDirty', codeIsDirty)
    @set('code', newCode)
    if codeIsDirty
      @fire('ntb-code-dirty')
    return

  recompile: () ->
    ntbCode = @assembleCode()
    @fire('ntb-recompile', ntbCode)
    @set('lastCode', ntbCode)
    @set('codeIsDirty', false)
    return

  assembleCode: () ->
    spaces = @get('spaces')
    spaceCodes = for space, _ in spaces
      "; Code for #{space.name}\n#{space.netLogoCode}".trim()
    spaceCodes.join("\n\n")

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
      , spaceNumber:       @get('nextId')
      , name:              "Block Space #{id}"
      , width:             430
      , height:            500
      , defs:              defs
      , defsJson:          JSON.stringify(defs, null, '  ')
      , defsJsonChanged:   false
    }
    for propName in [ 'name', 'width', 'height' ]
      if(spaceVals.hasOwnProperty(propName))
        space[propName] = spaceVals[propName]

    @push('spaces', space)
    @set('nextId', id + 1)
    return space

  data: () -> {
    playMode:         false,
    nextId:           0,
    spaces:           [],
    lastCompiledCode: "",
    codeIsDirty:      false,
    popupmenu:        null,
    blockEditForm:    null
  }

  components: {
    tangoSpace:    RactiveNetTangoSpace
    blockEditForm: RactiveNetTangoBlockForm
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <blockEditForm parentClass="ntb-container" horizontalOffset="{{ 0.5 }}" verticalOffset="{{ 0.25 }}" />

    <div class="ntb-block-defs-list">
      {{#spaces:spaceNum }}
        <tangoSpace space="{{ this }}" playMode="{{ playMode }}" popupmenu="{{ popupmenu }}" blockEditForm="{{ blockEditForm }}" />
      {{/spaces }}
    </div>
    <label for="ntb-code">NetLogo Code</label>
    <textarea id="ntb-code" readOnly>{{ code }}</textarea>
    """
    # coffeelint: enable=max_line_length
})
