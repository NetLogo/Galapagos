window.RactiveBlockForm = EditForm.extend({

  data: () -> {
    spaceName:   undefined # String
    block:       undefined # NetTangoBlock
    blockIndex:  undefined # Integer
    submitEvent: undefined # String
    showStyles:  false     # Boolean

    attributeTemplate:
      """
      <fieldset class="ntb-attribute">
        <legend class="widget-edit-legend">
          {{ itemType }} {{ number }} {{> delete-button }}
        </legend>
        <div class="flex-column">
          <attribute
            id="{{ number }}"
            attribute="{{ this }}"
            attributeType="{{ itemType }}"
            codeFormat="{{ codeFormat }}"
            />
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
      target.fire(@get('submitEvent'), {}, @getBlock(), @get('blockIndex'))
      return

    '*.code-changed': (_, code) ->
      @set("block.format", code)

    'ntb-clear-styles': (_) ->
      block = @get("block")
      [ 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
        .forEach( (prop) -> block[prop] = "" )
      @set("block", block)
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
    block.id = sourceBlock.id

    block.builderType =
      if      (block.type is "nlogo:procedure" or block.required)
        'Procedure'
      else if (block.type is "nlogo:if"        or (not block.required and block.clauses?.length is 0))
        '1 Block Clause (if/ask/create)'
      else if (block.type is "nlogo:ifelse"    or (not block.required and block.clauses?.length is 1))
        '2 Block Clause (ifelse)'
      else
        'Command'

    @set('block', block)
    return

  # (String, String, NetTangoBlock, Integer, String, String) => Unit
  show: (target, spaceName, block, blockIndex, submitLabel, submitEvent) ->
    @_setBlock(block)
    @set(     'target', target)
    @set(  'spaceName', spaceName)
    @set( 'blockIndex', blockIndex)
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

    [ 'action', 'format', 'note', 'required', 'limit', 'blockColor',
      'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace', 'id' ]
      .filter((f) -> blockValues.hasOwnProperty(f) and blockValues[f] isnt "")
      .forEach((f) -> block[f] = blockValues[f])

    switch blockValues.builderType
      when 'Procedure'
        block.type     = 'nlogo:procedure'
        block.required = true
        delete block.clauses
      when '1 Block Clause (if/ask/create)'
        block.type     = 'nlogo:if'
        block.required = false
        block.clauses  = []
      when '2 Block Clause (ifelse)'
        block.type     = 'nlogo:ifelse'
        block.required = false
        block.clauses  = [{ name: "else", action: "else", format: "" }]
      else
        block.type     = 'nlogo:command'
        block.required = false
        delete block.clauses

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
    , arrayView:    RactiveArrayView
    , attribute:    RactiveAttribute
    , blockStyle:   RactiveBlockStyleSettings
    , dropdown:     RactiveTwoWayDropdown
    , formCode:     RactiveEditFormMultilineCode
    , labeledInput: RactiveTwoWayLabeledInput
    , spacer:       RactiveEditFormSpacer
  }

  partials: {

    title: "{{ spaceName }} Block"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      {{# block }}

      <div class="flex-row ntb-form-row">

        <labeledInput id="block-{{ id }}-name" name="name" type="text" value="{{ action }}" labelStr="Display name"
          divClass="ntb-flex-column" class="ntb-input" />

        <dropdown id="block-{{ id }}-type" name="{{ builderType }}" selected="{{ builderType }}" label="Type"
          choices="{{ [ 'Procedure', 'Command', '1 Block Clause (if/ask/create)', '2 Block Clause (ifelse)' ] }}"
          divClass="ntb-flex-column"
          />

        <labeledInput id="block-{{ id }}-limit" name="limit" type="number" value="{{ limit }}" labelStr="Limit"
          min="1" max="100" divClass="ntb-flex-column" class="ntb-input" />

      </div>

      <div class="ntb-flex-column-code">
        <formCode id="block-{{ id }}-format" name="source" value="{{ format }}" label="NetLogo code format (use {#} for parameter, {P#} for property)" />
      </div>

      <div class="flex-row ntb-form-row">
        <labeledInput id="block-{{ id }}-note" name="note" type="text" value="{{ note }}"
          labelStr="Note - extra information for the code tip"
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
        codeFormat=""
        />

      <arrayView
        id="block-{{ id }}-properties"
        itemTemplate="{{ attributeTemplate }}"
        items="{{ properties }}"
        itemType="Property"
        itemTypePlural="Properties"
        createItem="{{ createAttribute('Property') }}"
        viewClass="ntb-attributes"
        codeFormat="P"
        />

      <label class="ntb-toggle-block" >
        <input type="checkbox" checked="{{ showStyles }}" twoway="true" />
        <div class="ntb-toggle-text">Block Styles
          {{# showStyles }}
            <button class="ntb-button" type="button" on-click="ntb-clear-styles">Clear Styles</button>▲
          {{else}}
            ▼
          {{/}}
        </div>
      </label>

      {{# showStyles }}

      <blockStyle styleId="{{ id }}" styleSettings="{{ this }}"></blockStyle>

      {{/ showStyles }}

      {{/block }}
      """
      # coffeelint: enable=max_line_length
  }
})
