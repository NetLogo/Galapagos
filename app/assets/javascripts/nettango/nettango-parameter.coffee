window.RactiveNetTangoParameter = Ractive.extend({

  data: () -> {
    number: undefined, # Integer
    p:      undefined, # NetTangoParameter
    pType:  undefined  # String ("params" or "properties")
  }

  on: {
    # (Context) => Unit
    '*.ntb-param-type-changed': (_) ->
      # Reset our default to the appropriate value  - JMB August 2018
      p = @get('p')
      newDefVal = switch p.type
        when 'bool' then false
        when 'num', 'int' then 10
        when 'text' then ""
        when 'range', 'select' then null
        else null
      @set('p.def', newDefVal)
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
      <labelledInput id="param-{{ number }}-name" name="name" type="text" value="{{ p.name }}" label="Name" style="flex-grow: 1;" />

      <dropdown id="param-{{ number }}-type" name="{{ p.type }}" value="{{ p.type }}" label="Type" style="flex-grow: 1;"
        options="{{ [ 'bool', 'num', 'int', 'range', 'text', 'select' ] }}" changeEvent="ntb-param-type-changed"
        />

      <labelledInput id="param-{{ number }}-unit" name="unit" type="text" value="{{ p.unit }}" label="Unit label" style="flex-grow: 1;" />
      <labelledInput id="param-{{ number }}-def"  name="def"  type="text" value="{{ p.def }}" label="Default"     style="flex-grow: 1;" />
    </div>
    {{> `param-${p.type}` }}
    <div>
      <button class="ntb-button" type="button" on-click="[ 'ntb-delete-p-thing', pType, number ]">Delete {{ p.name }} Parameter</button>
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
        <labelledInput id="param-{{ number }}-values" name="values" type="text" value="{{ p.valuesString }}" label="Options (; separated)" />
      </div>
      """

    'param-range':
      """
      <div class="flex-row">
        <labelledInput id="param-{{ number }}-min"  name="min"  type="number" value="{{ p.min }}"  label="Min" style="flex-grow: 1;" />
        <labelledInput id="param-{{ number }}-max"  name="max"  type="number" value="{{ p.max }}"  label="Max" style="flex-grow: 1;" />
        <labelledInput id="param-{{ number }}-step" name="step" type="number" value="{{ p.step }}" label="Step size" style="flex-grow: 1;" />
      </div>
      """
    # coffeelint: enable=max_line_length
  }
})
