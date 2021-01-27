window.RactiveBlockForm = EditForm.extend({

  data: () -> {
    ready:          false        # Boolean
    spaceName:      undefined    # String
    block:          undefined    # NetTangoBlock
    blockIndex:     undefined    # Integer
    blockKnownTags: []           # Array[String]
    allTags:        []           # Array[String]
    submitEvent:    undefined    # String
    terminalType:   "attachable" # "attachable" | "terminal"
  }

  computed: {
    canInheritTags: () ->
      block = @get('block')
      block.builderType isnt 'Procedure'

    terminalChoices: () ->
      [
        { value: "terminal",   text: "This will be the last block in its chain, no more blocks can attach" }
      , { value: "attachable", text: "Blocks can be attached to this block in a chain" }
      ]
  }

  on: {

    # (Context) => Unit
    'submit': (_) ->
      target = @get('target')
      # the user could've added a bunch of new known tags, but not wound up using them,
      # so ignore any that were not actually applied to the block - Jeremy B September 2020
      block          = @getBlock()
      blockKnownTags = @get('blockKnownTags')
      allTags        = @get('allTags')
      newKnownTags   = blockKnownTags.filter( (t) ->
        ( (block.tags? and block.tags.includes(t)) or
          (block.allowedTags?.tags? and block.allowedTags.tags.includes(t)) or
          (block.clauses.some( (c) -> c.allowedTags?.tags? and c.allowedTags.tags.includes(t) ))
        ) and
        not allTags.includes(t)
      )
      @push('allTags', ...newKnownTags)
      target.fire(@get('submitEvent'), {}, block, @get('blockIndex'))
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
      ready = @get('ready')
      if not ready
        return

      preview = @findComponent('preview')
      if not preview?
        return

      previewBlock = @getBlock()
      @set('previewBlock', previewBlock)
      preview.resetNetTango()
      return

    'terminalType': () ->
      terminalType = @get('terminalType')
      @set('block.isTerminal', terminalType is 'terminal')
      return

  }

  # (NetTangoBlock) => Unit
  _setBlock: (sourceBlock) ->
    # Copy so we drop any uncommitted changes - JMB August 2018
    block = NetTangoBlockDefaults.copyBlock(sourceBlock)
    block.id = sourceBlock.id

    block.builderType =
      if (block.required and block.placement is NetTango.blockPlacementOptions.STARTER)
        'Procedure'
      else if (not block.required and (not block.placement? or block.placement is NetTango.blockPlacementOptions.CHILD))
        'Command or Control'
      else
        'Custom'

    @set('block', block)
    @set('previewBlock', block)
    return

  # (String, String, NetTangoBlock, Integer, String, String, String) => Unit
  show: (target, spaceName, block, blockIndex, submitLabel, submitEvent, cancelLabel) ->
    @set('ready', false)
    @_setBlock(block)
    @set('blockKnownTags', @get('allTags').slice(0))
    @set(        'target', target)
    @set(     'spaceName', spaceName)
    @set(    'blockIndex', blockIndex)
    @set(   'submitLabel', submitLabel)
    @set(   'cancelLabel', cancelLabel)
    @set(   'submitEvent', submitEvent)
    @set(  'terminalType', if block.isTerminal? and block.isTerminal then 'terminal' else 'attachable')

    @fire('show-yourself')
    @set('ready', true)
    return

  # This does something useful for widgets in `EditForm`, but we don't need it - JMB August 2018
  genProps: (_) ->
    null

  # () => NetTangoBlock
  getBlock: () ->
    blockValues = @get('block')
    block = { }

    [
      'id'
    , 'action'
    , 'format'
    , 'closeClauses'
    , 'closeStarter'
    , 'note'
    , 'required'
    , 'isTerminal'
    , 'placement'
    , 'limit'
    , 'blockColor'
    , 'textColor'
    , 'borderColor'
    , 'fontWeight'
    , 'fontSize'
    , 'fontFace'
    ].filter( (f) -> blockValues.hasOwnProperty(f) and blockValues[f] isnt '' )
      .forEach( (f) -> block[f] = blockValues[f] )

    switch blockValues.builderType
      when 'Procedure'
        block.required  = true
        block.placement = NetTango.blockPlacementOptions.STARTER

      when 'Command or Control'
        block.required  = false
        block.placement = NetTango.blockPlacementOptions.CHILD
        block.tags      = blockValues.tags ? []

      else
        block.required  = blockValues.required  ? false
        block.placement = blockValues.placement ? falseNetTango.blockPlacementOptions.CHILD
        block.tags      = blockValues.tags ? []

    block.clauses     = @processClauses(blockValues.clauses ? [])
    block.params      = @processAttributes(blockValues.params)
    block.properties  = @processAttributes(blockValues.properties)
    block.allowedTags = @processAllowedTags(blockValues.allowedTags)

    block

  processClauses: (clauses) ->
    pat = @processAllowedTags

    clauses.map( (clause) ->
      [ 'action', 'open', 'close' ].forEach( (f) ->
        if clause.hasOwnProperty(f) and clause[f] is ''
          delete clause[f]
      )

      clause.allowedTags = pat(clause.allowedTags)

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

  processAllowedTags: (allowedTags) ->
    if not allowedTags?
      return undefined

    if allowedTags.type isnt 'any-of'
      delete allowedTags.tags

    allowedTags

  components: {
    allowedTags:  RactiveAllowedTags
  , attributes:   RactiveAttributes
  , blockStyle:   RactiveBlockStyleSettings
  , clauses:      RactiveClauses
  , codeMirror:   RactiveCodeMirror
  , dropdown:     RactiveTwoWayDropdown
  , labeledInput: RactiveTwoWayLabeledInput
  , preview:      RactiveBlockPreview
  , tagsControl:  RactiveToggleTags
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

        <div class="flex-row ntb-form-row">
          <dropdown id="block-{{ id }}-terminal" name="terminal" selected="{{ terminalType }}" label="Can blocks follow this one in a chain?"
            choices={{ terminalChoices }}
            divClass="ntb-flex-column"
            />
        </div>

        {{# builderType === 'Command or Control' }}
          <tagsControl tags={{ tags }} knownTags={{ blockKnownTags }} showAtStart={{ tags.length > 0 }} />

        {{else}}
          <div class="flex-row ntb-form-row">
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

          {{# !isTerminal }}
          <div class="flex-row ntb-form-row">
            <allowedTags
              id="block-{{ id }}-allowed-tags"
              allowedTags={{ allowedTags }}
              knownTags={{ blockKnownTags }}
              blockType="starter"
              canInheritTags=false
              />
          </div>
          {{/ isTerminal}}

        {{/if}}

        <attributes
          singular="Parameter"
          plural="Parameters"
          blockId={{ id }}
          attributes={{ params }}
          />

        <attributes
          singular="Property"
          plural="Properties"
          blockId={{ id }}
          attributes={{ properties }}
          codeFormat="P"
          />

        <clauses
          blockId={{ id }}
          clauses={{ clauses }}
          closeClauses={{ closeClauses }}
          knownTags={{ blockKnownTags }}
          canInheritTags={{ canInheritTags }}
          />

        <blockStyle styleId="{{ id }}" showAtStart=false styleSettings="{{ this }}"></blockStyle>

      {{/block }}
      </div>

      <preview block={{ previewBlock }} blockStyles={{ blockStyles }} />

      </div>
      """
      # coffeelint: enable=max_line_length
  }
})
