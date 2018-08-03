window.RactiveNetTangoBlockForm = EditForm.extend({

  data: () -> {
    spaceName:   undefined # String
    block:       undefined # NetTangoBlock
    blockNumber: undefined # Integer
    submitEvent: undefined # String
  }

  on: {

    # (Context) => Unit
    'submit': (_) ->
      target = @get('target')
      target.fire(@get('submitEvent'), {}, @getBlock(), @get('blockNumber'))
      return

    # (Context, String) => Boolean
    'ntb-add-p-thing': (_, pType) ->
      num = @get("block.#{pType}.length")
      @push("block.#{pType}", @defaultParam(pType, num))
      return false

    # (Context, String, Integer) => Boolean
    '*.ntb-delete-p-thing': (_, pType, num) ->
      @splice("block.#{pType}", num, 1)
      return false

  }

  oninit: ->
    @_super()

  # (String, Integer) => NetTangoParameter
  defaultParam: (pType, num) -> {
      name: "#{pType}#{num}"
    , type: "num"
    , unit: undefined
    , def:  "10"
  }

  # (NetTangoBlock) => Unit
  _setBlock: (sourceBlock) ->
    # Copy so we drop any uncommitted changes
    block = NetTangoBlockDefaults.copyBlock(sourceBlock)

    block.builderType = switch block.type
      when "nlogo:procedure" or (block.start and not block.control)
        'Procedure'
      when "nlogo:if"        or (not block.start and block.control and block.clauses?.length is 0)
        '1 Block Clause (if/ask/create)'
      when "nlogo:ifelse"    or (not block.start and block.control and block.clauses?.length is 1)
        '2 Block Clause (ifelse)'
      else
        'Command'

    @set('block', block)
    return

  # (String, String, NetTangoBlock, Integer, String, String) => Unit
  show: (target, spaceName, block, blockNumber, submitLabel, submitEvent) ->
    @_setBlock(block)
    @set('target', target)
    @set('spaceName', spaceName)
    @set('blockNumber', blockNumber)
    @set('submitLabel', submitLabel)
    @set('submitEvent', submitEvent)
    @fire('show-yourself')
    return

  # This does something useful for widgets in `EditForm`, but we don't need it
  genProps: (_) ->
    null

  # () => NetTangoBlock
  getBlock: () ->
    blockValues = @get('block')
    block = { }

    # coffeelint: disable=max_line_length
    [ 'action', 'format', 'required', 'limit', 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
      .filter((f) -> blockValues.hasOwnProperty(f) and blockValues[f] isnt "")
      .forEach((f) -> block[f] = blockValues[f])
    # coffeelint: enable=max_line_length

    switch blockValues.builderType
      when 'Procedure'
        block.type    = 'nlogo:procedure'
        block.start   = true
        block.control = false
      when '1 Block Clause (if/ask/create)'
        block.type    = 'nlogo:if'
        block.start   = false
        block.control = true
        block.clauses = []
      when '2 Block Clause (ifelse)'
        block.type    = 'nlogo:ifelse'
        block.start   = false
        block.control = true
        block.clauses = [{ name: "else", action: "else", format: "" }]
      else
        block.type    = 'nlogo:command'
        block.start   = false
        block.control = false

    block.params     = @processPThings(blockValues.params)
    block.properties = @processPThings(blockValues.properties)

    block

  # (Array[NetTangoParameter]) => Array[NetTangoParameter]
  processPThings: (pThings) ->
    pCopies = for pValues in pThings
      pThing = { }
      [ 'name', 'unit', 'type' ].forEach((f) -> pThing[f] = pValues[f])
      # Using `default` as a property name gives Ractive some issues, so we "translate" it back here.
      pThing.default = pValues.def
      # User may have switched type a couple times, so only copy the properties if the type is appropriate to them
      if pValues.type is 'range'
        [ 'min', 'max', 'step' ].forEach((f) -> pThing[f] = pValues[f])
      else if pValues.type is 'select'
        pThing.values = pValues.valuesString.split(/\s*;\s*|\n/).filter((s) -> s isnt "")
      pThing

    pCopies

  components: {
      formCheckbox:  RactiveEditFormCheckbox
    , formCode:      RactiveCodeContainerOneLine
    , formDropdown:  RactiveEditFormDropdown
    , spacer:        RactiveEditFormSpacer
    , labelledInput: RactiveLabelledInput
    , dropdown:      RactiveDropdown
    , parameter:     RactiveNetTangoParameter
  }

  partials: {

    title: "{{ spaceName }} Block"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      {{# block }}

      <labelledInput id="{{ id }}-name" name="name" type="text" value="{{ action }}" label="Display name" style="flex-grow: 1;" />

      <spacer height="15px" />

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <dropdown id="{{ id }}-type" name="{{ builderType }}" value="{{ builderType }}" label="Type"
          options="{{ [ 'Procedure', 'Command', '1 Block Clause (if/ask/create)', '2 Block Clause (ifelse)' ] }}"
          />
        <labelledInput id="{{ id }}-limit" name="limit" type="number" value="{{ limit }}" label="Limit" style="flex-grow: 1;"
          min="1" max="100" />
      </div>

      <spacer height="15px" />

      <labelledInput id="{{ id }}-format" name="format" type="text" value="{{ format }}" label="Code Format ({#} for param, {P#} for property)" style="flex-grow: 1;" />

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <labelledInput id="{{ id }}-f-weight" name="font-weight" type="number" value="{{ fontWeight }}" label="Font weight" style="flex-grow: 1;" />
        <labelledInput id="{{ id }}-f-size"   name="font-size"   type="number" value="{{ fontSize }}"   label="Font size"   style="flex-grow: 1;" />
        <labelledInput id="{{ id }}-f-face"   name="font-face"   type="text"   value="{{ fontFace }}"   label="Typeface"    style="flex-grow: 2;" />
      </div>

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <labelledInput id="{{ id }}-block-color"  name="block-color"  type="color" value="{{ blockColor }}"  label="Block color"  style="flex-grow: 1;" twoway="true" />
        <labelledInput id="{{ id }}-text-color"   name="text-color"   type="color" value="{{ textColor }}"   label="Text color"   style="flex-grow: 1;" />
        <labelledInput id="{{ id }}-border-color" name="border-color" type="color" value="{{ borderColor }}" label="Border color" style="flex-grow: 1;" />
      </div>

      <div class="flex-column" >
        <div class="ntb-block-defs-controls">
          <label>Block Parameters</label>
          <button class="ntb-button" type="button" on-click="[ 'ntb-add-p-thing', 'params' ]">Add Parameter</button>
        </div>
        {{#params:number }}
          <parameter number="{{ number }}" p="{{ this }}" pType="params" />
        {{/params }}
      </div>

      <div class="flex-column" >
        <div class="ntb-block-defs-controls">
          <label>Block Properties</label>
          <button class="ntb-button" type="button" on-click="[ 'ntb-add-p-thing', 'properties' ]">Add Property</button>
        </div>
        {{#properties:number }}
          <parameter number="{{ number }}" p="{{ this }}" pType="properties" />
        {{/properties }}
      </div>

      {{/block }}
      """
      # coffeelint: enable=max_line_length
  }
})
