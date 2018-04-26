window.RactiveDropdown = Ractive.extend({
  on: {
    '*.changed': (_) ->
      event = @get('changeEvent')
      if (event?)
        @fire(event)
  }
  data: () -> {
    style: undefined # String
    id:    undefined # String
    value: undefined # Any
    name:  undefined # String
    label: undefined # String
    options: undefined # Array[String]
    changeEvent: undefined # String
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div style="flex: column; padding: 0px;{{ style }}">
      <label for="{{ id }}">{{ label }}</label>
      <select id="{{ id }}" value="{{ value }}" twoway="true" style="margin: 6px; font-size: 16pt;" on-change="changed" >
        {{#options }}
          <option>{{ this }}</option>
        {{/options }}
      </select>
    </div>
    """
    # coffeelint: enable=max_line_length
})
