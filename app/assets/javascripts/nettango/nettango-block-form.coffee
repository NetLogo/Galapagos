window.RactiveNetTangoBlockForm = EditForm.extend({

  data: () -> {
    spaceName:   undefined # String
    block:       undefined # NetTangoBlock
    blockNumber: undefined # Integer
    submitEvent: undefined # String
    attributeTemplate:
      """
      <fieldset class="ntb-attribute">
        <legend class="widget-edit-legend">
          {{ itemType }} {{ number }} {{> delete-button }}
        </legend>
        <div class="flex-column">
          <attribute id="{{ number }}" attribute="{{ this }}" attributeType="{{ itemType }}" />
        </div>
      </fieldset>
      """
    createAttribute:
      (type) -> (number) -> { name: "#{type} #{number}", type: "num", unit: undefined, def:  "10" }

  }

  on: {

    # (Context) => Unit
    'submit': (_) ->
      target = @get('target')
      target.fire(@get('submitEvent'), {}, @getBlock(), @get('blockNumber'))
      return

  }

  oninit: ->
    @_super()

  # (String, Integer) => NetTangoAttribute
  defaultAttribute: (attributeType, num) -> {
      name: "#{attributeType}#{num}"
    , type: "num"
    , unit: undefined
    , def:  "10"
  }

  # (NetTangoBlock) => Unit
  _setBlock: (sourceBlock) ->
    # Copy so we drop any uncommitted changes - JMB August 2018
    block = NetTangoBlockDefaults.copyBlock(sourceBlock)

    block.builderType =
      if      (block.type is "nlogo:procedure" or (block.start and not block.control))
        'Procedure'
      else if (block.type is "nlogo:if"        or (not block.start and block.control and block.clauses?.length is 0))
        '1 Block Clause (if/ask/create)'
      else if (block.type is "nlogo:ifelse"    or (not block.start and block.control and block.clauses?.length is 1))
        '2 Block Clause (ifelse)'
      else
        'Command'

    @set('block', block)
    return

  # (String, String, NetTangoBlock, Integer, String, String) => Unit
  show: (target, spaceName, block, blockNumber, submitLabel, submitEvent) ->
    @_setBlock(block)
    @set(     'target', target)
    @set(  'spaceName', spaceName)
    @set('blockNumber', blockNumber)
    @set('submitLabel', submitLabel)
    @set('submitEvent', submitEvent)
    @fire('show-yourself')
    return

  # This does something useful for widgets in `EditForm`, but we don't need it - JMB August 2018
  genProps: (_) ->
    null

  # () => NetTangoBlock
  getBlock: () ->
    blockValues = @get('block')
    block = { }

    [ 'action', 'format', 'required', 'limit', 'blockColor',
      'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
      .filter((f) -> blockValues.hasOwnProperty(f) and blockValues[f] isnt "")
      .forEach((f) -> block[f] = blockValues[f])

    switch blockValues.builderType
      when 'Procedure'
        block.type    = 'nlogo:procedure'
        block.start   = true
        block.control = false
        block.clauses = null
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
        block.clauses = null

    block.params     = @processAttributes(blockValues.params)
    block.properties = @processAttributes(blockValues.properties)

    block

  # (Array[NetTangoAttribute]) => Array[NetTangoAttribute]
  processAttributes: (attributes) ->
    attributeCopies = for attrValues in attributes
      attribute = { }
      [ 'name', 'unit', 'type' ].forEach((f) -> attribute[f] = attrValues[f])
      # Using `default` as a property name gives Ractive some issues, so we "translate" it back here - JMB August 2018
      attribute.default = attrValues.def
      # User may have switched type a couple times, so only copy the properties if the type is appropriate to them
      # - JMB August 2018
      if attrValues.type is 'range'
        [ 'min', 'max', 'step' ].forEach((f) -> attribute[f] = attrValues[f])
      else if attrValues.type is 'select'
        attribute.values = attrValues.values

      attribute

    attributeCopies

  components: {
    , spacer:       RactiveEditFormSpacer
    , labeledInput: RactiveTwoWayLabeledInput
    , dropdown:     RactiveTwoWayDropdown
    , attribute:    RactiveNetTangoAttribute
    , arrayView:    RactiveArrayView
  }

  partials: {

    title: "{{ spaceName }} Block"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      {{# block }}

      <div class="flex-row ntb-form-row">

        <labeledInput id="{{ id }}-name" name="name" type="text" value="{{ action }}" labelStr="Display name"
          divClass="ntb-flex-column" class="ntb-input" />

        <dropdown id="{{ id }}-type" name="{{ builderType }}" selected="{{ builderType }}" label="Type"
          choices="{{ [ 'Procedure', 'Command', '1 Block Clause (if/ask/create)', '2 Block Clause (ifelse)' ] }}"
          divClass="ntb-flex-column"
          />

        <labeledInput id="{{ id }}-limit" name="limit" type="number" value="{{ limit }}" labelStr="Limit"
          min="1" max="100" divClass="ntb-flex-column" class="ntb-input" />

      </div>

      <labeledInput id="{{ id }}-format" name="format" type="text" value="{{ format }}" labelStr="Code Format ({#} for param, {P#} for property)"
        divClass="ntb-flex-column" class="ntb-input" />

      <div class="flex-row ntb-form-row">
        <labeledInput id="{{ id }}-block-color"  name="block-color"  type="color" value="{{ blockColor }}"  labelStr="Block color"
          divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="{{ id }}-text-color"   name="text-color"   type="color" value="{{ textColor }}"   labelStr="Text color"
          divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="{{ id }}-border-color" name="border-color" type="color" value="{{ borderColor }}" labelStr="Border color"
          divClass="ntb-flex-column" class="ntb-input" />
      </div>

      <arrayView
        id="block-{{ id }}-parameters"
        itemTemplate="{{ attributeTemplate }}"
        items="{{ params }}"
        itemType="Parameter"
        itemTypePlural="Parameters"
        createItem="{{ createAttribute('Parameter') }}"
        viewClass="ntb-attributes"
        />

      <arrayView
        id="block-{{ id }}-properties"
        itemTemplate="{{ attributeTemplate }}"
        items="{{ properties }}"
        itemType="Property"
        itemTypePlural="Properties"
        createItem="{{ createAttribute('Property') }}"
        viewClass="ntb-attributes"
        />

      <div class="flex-row ntb-form-row">
        <labeledInput id="{{ id }}-f-weight" name="font-weight" type="number" value="{{ fontWeight }}" labelStr="Font weight"
          divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="{{ id }}-f-size"   name="font-size"   type="number" value="{{ fontSize }}"   labelStr="Font size"
          divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="{{ id }}-f-face"   name="font-face"   type="text"   value="{{ fontFace }}"   labelStr="Typeface"
          divClass="ntb-flex-column" class="ntb-input" />
      </div>

      {{/block }}
      """
      # coffeelint: enable=max_line_length
  }
})
