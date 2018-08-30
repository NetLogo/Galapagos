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
    labelledInput: RactiveLabelledInput
    dropdown:      RactiveDropdown
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="flex-row ntb-form-row">
      <labelledInput id="param-{{ id }}-name" name="name" type="text" value="{{ attribute.name }}" label="Name" style="flex-grow: 1;" />

      <dropdown id="param-{{ id }}-type" name="{{ attribute.type }}" value="{{ attribute.type }}" label="Type" style="flex-grow: 1;"
        options="{{ [ 'bool', 'num', 'int', 'range', 'text', 'select' ] }}" changeEvent="ntb-attribute-type-changed"
        />

      <labelledInput id="param-{{ id }}-unit" name="unit" type="text" value="{{ attribute.unit }}" label="Unit label" style="flex-grow: 1;" />
      <labelledInput id="param-{{ id }}-def"  name="def"  type="text" value="{{ attribute.def }}" label="Default"  style="flex-grow: 1;" />
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
        <labelledInput id="param-{{ id }}-values" name="values" type="text" value="{{ attribute.valuesString }}" label="Options (; separated)" />
      </div>
      """

    'param-range':
      """
      <div class="flex-row">
        <labelledInput id="param-{{ id }}-min"  name="min"  type="number" value="{{ attribute.min }}"  label="Min" style="flex-grow: 1;" />
        <labelledInput id="param-{{ id }}-max"  name="max"  type="number" value="{{ attribute.max }}"  label="Max" style="flex-grow: 1;" />
        <labelledInput id="param-{{ id }}-step" name="step" type="number" value="{{ attribute.step }}" label="Step size" style="flex-grow: 1;" />
      </div>
      """
    # coffeelint: enable=max_line_length
  }
})
