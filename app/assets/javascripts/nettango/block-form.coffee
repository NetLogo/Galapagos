window.RactiveBlockForm = EditForm.extend({

  data: () -> {
    spaceName:   undefined # String
    block:       undefined # NetTangoBlock
    blockIndex:  undefined # Integer
    knownTags:   []        # Array[String]
    showStyles:  false     # Boolean
    submitEvent: undefined # String

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

    clauseTemplate:
      """
      <fieldset class="ntb-attribute">
        <legend class="widget-edit-legend">
          {{ itemType }} {{ number }} {{> delete-button }}
        </legend>
        <div class="flex-column">
          <div class="flex-row ntb-form-row">

            <labeledInput name="action" type="text" value="{{ action }}" labelStr="Display name"
              divClass="ntb-flex-column" class="ntb-input" />

            <div class="ntb-flex-column">
              <label for="block-{{ id }}-clause-{{ number }}-open">Start code format (default is `[`)</label>
              <codeMirror
                id="block-{{ id }}-clause-{{ number }}-open"
                mode="netlogo"
                code={{ open }}
                extraClasses="['ntb-code-input']"
              />
            </div>

            <div class="ntb-flex-column">
              <label for="block-{{ id }}-clause-{{ number }}-close">End code format (default is `]`)</label>
              <codeMirror
                id="block-{{ id }}-clause-{{ number }}-close"
                mode="netlogo"
                code={{ close }}
                extraClasses="['ntb-code-input']"
              />
            </div>

          </div>
        </div>
      </fieldset>
      """

    clauseHeaderTemplate:
      """
      <div class="flex-column">
        <div class="flex-row ntb-form-row">

          <div class="ntb-flex-column">
            <label for="block-{{ id }}-close-clauses">Code format to insert after all clauses</label>
            <codeMirror
              id="block-{{ id }}-close-clauses"
              mode="netlogo"
              code={{ closeClauses }}
              extraClasses="['ntb-code-input']"
            />
          </div>

        </div>
      </div>
      """

    createAttribute:
      (type) -> (number) -> { name: "#{type} #{number}", type: 'int', unit: undefined, def: '10' }

    createClause:
      (number) -> { open: undefined, close: undefined, children: [] }

  }

  on: {

    # (Context) => Unit
    'submit': (_) ->
      target = @get('target')
      target.fire(@get('submitEvent'), {}, @getBlock(), @get('blockIndex'))
      return

    '*.code-changed': (_, code) ->
      @set('block.format', code)

    '*.ntb-clear-styles': (_) ->
      block = @get('block')
      [ 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
        .forEach( (prop) -> block[prop] = '' )
      @set('block', block)
      return

  }

  oninit: ->
    @_super()

  observe: {
    'block.*': () ->
      preview = @findComponent('preview')
      if not preview?
        return

      previewBlock = @getBlock()
      @set('previewBlock', previewBlock)
      preview.resetNetTango()
      return
  }

  # (String, Integer) => NetTangoAttribute
  defaultAttribute: (attributeType, num) -> {
      name: "#{attributeType}#{num}"
    , type: 'num'
    , unit: undefined
    , def:  '10'
  }

  # (NetTangoBlock) => Unit
  _setBlock: (sourceBlock) ->
    # Copy so we drop any uncommitted changes - JMB August 2018
    block = NetTangoBlockDefaults.copyBlock(sourceBlock)
    block.id = sourceBlock.id

    block.builderType =
      if (block.required and block.placement is NetTango.blockPlacementOptions.starter)
        'Procedure'
      else if (not block.required and (not block.placement? or block.placement is NetTango.blockPlacementOptions.child))
        'Command or Control'
      else
        'Custom'

    @set('block', block)
    @set('previewBlock', block)
    return

  # (String, String, NetTangoBlock, Integer, String, String, String) => Unit
  show: (target, spaceName, block, blockIndex, submitLabel, submitEvent, cancelLabel) ->
    @_setBlock(block)
    @set(     'target', target)
    @set(  'spaceName', spaceName)
    @set( 'blockIndex', blockIndex)
    @set('submitLabel', submitLabel)
    @set('cancelLabel', cancelLabel)
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

    [ 'id', 'action', 'format', 'closeClauses', 'closeStarter', 'note',
      'required', 'isTerminal', 'placement', 'limit',
      'blockColor', 'textColor', 'borderColor',
      'fontWeight', 'fontSize', 'fontFace' ]
      .filter((f) -> blockValues.hasOwnProperty(f) and blockValues[f] isnt '')
      .forEach((f) -> block[f] = blockValues[f])

    switch blockValues.builderType
      when 'Procedure'
        block.required  = true
        block.placement = NetTango.blockPlacementOptions.starter

      when 'Command or Control'
        block.required  = false
        block.placement = NetTango.blockPlacementOptions.child
        block.tags      = blockValues.tags ? []

      else
        block.required  = blockValues.required  ? false
        block.placement = blockValues.placement ? falseNetTango.blockPlacementOptions.child
        block.tags      = blockValues.tags ? []

    block.clauses    = @processClauses(blockValues.clauses ? [])
    block.params     = @processAttributes(blockValues.params)
    block.properties = @processAttributes(blockValues.properties)

    block

  processClauses: (clauses) ->
    clauses.map( (clause) ->
      [ 'action', 'open', 'close' ].forEach( (f) ->
        if clause.hasOwnProperty(f) and clause[f] is ''
          delete clause[f]
      )

      clause
    )

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
        [ 'quoteValues' ].forEach((f) -> attribute[f] = attrValues[f])
        attribute.values = attrValues.values

      attribute

    attributeCopies

  components: {
    , arrayView:    RactiveArrayView
    , attribute:    RactiveAttribute
    , blockStyle:   RactiveBlockStyleSettings
    , codeMirror:   RactiveCodeMirror
    , dropdown:     RactiveTwoWayDropdown
    , labeledInput: RactiveTwoWayLabeledInput
    , preview:      RactiveBlockPreview
    , spacer:       RactiveEditFormSpacer
    , tagsControl:  RactiveTags
  }

  partials: {

    title: "{{ spaceName }} Block"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      <div class="flex-row ntb-block-form">

      <div class="ntb-block-form-fields">
      {{# block }}

        <div class="flex-row ntb-form-row">

          <labeledInput id="block-{{ id }}-name" name="name" type="text" value="{{ action }}" labelStr="Display name"
            divClass="ntb-flex-column" class="ntb-input" />

          <dropdown id="block-{{ id }}-type" name="{{ builderType }}" selected="{{ builderType }}" label="Type"
            choices="{{ [ 'Procedure', 'Command or Control' ] }}"
            divClass="ntb-flex-column"
            />

          <labeledInput id="block-{{ id }}-limit" name="limit" type="number" value="{{ limit }}" labelStr="Limit"
            min="1" max="100" divClass="ntb-flex-column" class="ntb-input" />

        </div>

        <div class="ntb-flex-column">
          <label for="block-{{ id }}-format">NetLogo code format (use {#} for parameter, {P#} for property)</label>
          <codeMirror
            id="block-{{ id }}-format"
            mode="netlogo"
            code={{ format }}
            extraClasses="['ntb-code-input-big']"
          />
        </div>

        <div class="flex-row ntb-form-row">
          <labeledInput id="block-{{ id }}-note" name="note" type="text" value="{{ note }}"
            labelStr="Note - extra information for the code tip"
            divClass="ntb-flex-column" class="ntb-input" />
        </div>

        {{# builderType === 'Command or Control' }}
          <tagsControl tags={{ tags }} knownTags={{ knownTags }} />
        {{else}}
          <div class="flex-row ntb-form-row">

            <labeledInput id="block-{{ id }}-terminal" name="terminal" type="checkbox" checked="{{ isTerminal }}"
              labelStr="Make this the final block in a chain"
              divClass="ntb-flex-column" class="ntb-input" />

            <div class="ntb-flex-column">
              <label for="block-{{ id }}-close">Code format to insert after all attached blocks (default is `end`)</label>
              <codeMirror
                id="block-{{ id }}-close"
                mode="netlogo"
                code={{ closeStarter }}
                extraClasses="['ntb-code-input']"
              />
            </div>

          </div>
        {{/if}}

        <arrayView
          id="block-{{ id }}-parameters"
          itemTemplate="{{ attributeTemplate }}"
          items="{{ params }}"
          itemType="Parameter"
          itemTypePlural="Parameters"
          createItem="{{ createAttribute('Parameter') }}"
          viewClass="ntb-block-array"
          codeFormat=""
          showItems="{{ params.length > 0 }}"
          />

        <arrayView
          id="block-{{ id }}-properties"
          itemTemplate="{{ attributeTemplate }}"
          items="{{ properties }}"
          itemType="Property"
          itemTypePlural="Properties"
          createItem="{{ createAttribute('Property') }}"
          viewClass="ntb-block-array"
          codeFormat="P"
          showItems="{{ properties.length > 0 }}"
          />

        <arrayView
          id="block-{{ id }}-clauses"
          itemTemplate="{{ clauseTemplate }}"
          items="{{ clauses }}"
          itemType="Clause"
          itemTypePlural="Control Clauses"
          createItem="{{ createClause }}"
          viewClass="ntb-block-array"
          headerItem="{{ block }}"
          headerTemplate="{{ clauseHeaderTemplate }}"
          showItems="{{ clauses.length > 0 }}"
          />

        <blockStyle styleId="{{ id }}" showStyles="{{ showStyles }}" styleSettings="{{ this }}"></blockStyle>

      {{/block }}
      </div>

      <preview block={{ previewBlock }} blockStyles={{ blockStyles }} />

      </div>
      """
      # coffeelint: enable=max_line_length
  }
})
