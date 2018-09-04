window.RactiveNetTangoAttribute = Ractive.extend({

  data: () -> {
    id:             undefined, # Integer
    attribute:      undefined, # NetTangoAttribute
    atttributeType: undefined  # String ("params" or "properties")
  }

  on: {
    # (Context) => Unit
    '*.ntb-attribute-type-changed': (_) ->
      # Reset our default to the appropriate value  - JMB August 2018
      attribute = @get('attribute')
      newDefVal = switch attribute.type
        when 'bool'            then false
        when 'num',   'int'    then 10
        when 'text'            then ""
        when 'range', 'select' then null
        else null
      @set('attribute.def', newDefVal)
      return
  }

  components: {
    labeledInput: RactiveTwoWayLabeledInput
    dropdown:     RactiveTwoWayDropdown
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-row ntb-form-row">
      <labeledInput id="param-{{ id }}-name" name="name" type="text" value="{{ attribute.name }}" labelStr="Name" divClass="ntb-flex-column" class="ntb-input" />

      <dropdown id="param-{{ id }}-type" name="{{ attribute.type }}" selected="{{ attribute.type }}" label="Type" divClass="ntb-flex-column"
        choices="{{ [ 'bool', 'num', 'int', 'range', 'text', 'select' ] }}" changeEvent="ntb-attribute-type-changed"
        />

      <labeledInput id="param-{{ id }}-unit" name="unit" type="text" value="{{ attribute.unit }}" labelStr="Unit label" divClass="ntb-flex-column" class="ntb-input" />
      <labeledInput id="param-{{ id }}-def"  name="def"  type="text" value="{{ attribute.def }}" labelStr="Default" divClass="ntb-flex-column" class="ntb-input" />
    </div>
    {{> `param-${attribute.type}` }}
    <div>
      <button class="ntb-button" type="button" on-click="[ 'ntb-delete-attribute', attributeType, id ]">Delete {{ attribute.name }} Parameter</button>
    </div>
    """
    # coffeelint: enable=max_line_length

  partials: {
    # coffeelint: disable=max_line_length
    'param-bool': ""
    'param-num': ""
    'param-int': ""
    'param-text': ""

    'param-select':
      """
      <div class="flex-row">
        <labeledInput id="param-{{ id }}-values" name="values" type="text" value="{{ attribute.valuesString }}" labelStr="Options (; separated)" divClass="ntb-flex-column" class="ntb-input" />
      </div>
      """

    'param-range':
      """
      <div class="flex-row">
        <labeledInput id="param-{{ id }}-min"  name="min"  type="number" value="{{ attribute.min }}"  labelStr="Min" divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="param-{{ id }}-max"  name="max"  type="number" value="{{ attribute.max }}"  labelStr="Max" divClass="ntb-flex-column" class="ntb-input" />
        <labeledInput id="param-{{ id }}-step" name="step" type="number" value="{{ attribute.step }}" labelStr="Step size" divClass="ntb-flex-column" class="ntb-input" />
      </div>
      """
    # coffeelint: enable=max_line_length
  }
})
