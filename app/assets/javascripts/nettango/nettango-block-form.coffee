window.RactiveNetTangoBlockForm = EditForm.extend({
  data: () -> {
    spaceName:   undefined # String
    spaceNumber: undefined # String
    block:       undefined # Block
    blockNumber: undefined # Integer
    submitEvent: undefined # String
  }

  on: {

    'submit': (_) ->
      @fire(@get('submitEvent'), @get('spaceNumber'), @getBlock(), @get('blockNumber'))
      # Reset the "working" block to have new values in case it isn't reset before next open
      @set('block', NetTangoBlockDefaults.getBlockDefault('basics', 0))
      return

    'ntb-add-parameter': (_) ->
      num = @get('block.params.length')
      @push('block.params', @defaultParam(num))
      return false

  }

  oninit: ->
    @_super()

  components: {
      formCheckbox:  RactiveEditFormCheckbox
    , formCode:      RactiveCodeContainerOneLine
    , formDropdown:  RactiveEditFormDropdown
    , spacer:        RactiveEditFormSpacer
    , labelledInput: RactiveLabelledInput
    , dropdown:      RactiveDropdown
    , parameter:     RactiveNetTangoParameter
  }

  defaultParam: (num) -> {
      name: "param#{num}"
    , type: "num"
    , unit: undefined
    , def:  "10"
  }

  setBlock: (block) ->
    block.params.filter((p) -> p.type is 'select' and p['values']).forEach((p) ->
      p['valuesString'] = p['values'].join(';')
    )
    @set('block', block)
    return

  # this does something useful for widgets, but not for us, I think?
  genProps: (_) ->
    null

  getBlock: () ->
    blockValues = @get('block')
    block = { }
    # coffeelint: disable=max_line_length
    [ 'action', 'type', 'format', 'start', 'required', 'limit', 'blockColor', 'textColor', 'borderColor', 'fontWeight', 'fontSize', 'fontFace' ]
      .filter((f) -> blockValues.hasOwnProperty(f) and blockValues[f] != "")
      .forEach((f) -> block[f] = blockValues[f])
    # coffeelint: enable=max_line_length
    if blockValues.control
      block['clauses'] = []

    block.params = for paramValues in blockValues.params
      param = { }
      [ 'name', 'unit', 'type' ].forEach((f) -> param[f] = paramValues[f])
      # Using `default` as a property name gives Ractive some issues, so we "translate" it back here.
      param['default'] = paramValues['def']
      # User may have switched type a couple times, so only copy the properties if the type is appropriate to them
      if paramValues.type is 'range'
        [ 'min', 'max', 'step' ].forEach((f) -> param[f] = paramValues[f])
      else if paramValues.type is 'select'
        param['values'] = paramValues['valuesString'].split(/\s*;\s*|\n/).filter((s) -> s != "")
      param

    block

  partials: {

    title: "{{ spaceName }} Block"

    widgetFields:
      # coffeelint: disable=max_line_length
      """
      {{# block }}

      <labelledInput id="{{ id }}-name" name="name" type="text" value="{{ action }}" label="Display name" style="flex-grow: 1;" />

      <spacer height="15px" />

      <dropdown id="{{ id }}-type" name="{{ type }}" value="{{ type }}" label="Type"
        options="{{ [ 'nlogo:procedure', 'nlogo:command', 'nlogo:if', 'nlogo:ifelse', 'nlogo:ask' ] }}"
        />

      <spacer height="15px" />

      <labelledInput id="{{ id }}-format" name="format" type="text" value="{{ format }}" label="Format" style="flex-grow: 1;" />

      <div class="flex-row ntb-form-row" style="align-items: center;">
        <formCheckbox id="{{ id }}-start" isChecked={{ start }} labelText="Start Block" name="startblock" />
        <formCheckbox id="{{ id }}-control" isChecked={{ control }} labelText="Control Block" name="controlblock" />
        <labelledInput id="{{ id }}-limit" name="limit" type="number" value="{{ limit }}" label="Limit" style="flex-grow: 1;" />
      </div>

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
          <button class="ntb-button" on-click="ntb-add-parameter">Add Parameter</button>
        </div>
        {{#params:number }}
          <parameter number="{{ number }}" p="{{ this }}" />
        {{/params }}
      </div>

      {{/block }}
      """
      # coffeelint: enable=max_line_length
  }
})
