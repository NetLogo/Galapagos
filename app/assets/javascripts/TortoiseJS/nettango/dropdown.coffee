window.RactiveDropdown = Ractive.extend({
  data: () -> {
    style: undefined # String
    id:    undefined # String
    value: undefined # Any
    name:  undefined # String
    label: undefined # String
    options: undefined # Array[String]
  }

  template: """
    <div style="flex: column; padding: 0px;{{ style }}">
      <label for="{{ id }}">{{ label }}</label>
      <select id="{{ id }}" value="{{ value }}" twoway="true" style="margin: 6px; font-size: 16pt;"  >
        {{#options }}
          <option>{{ this }}</option>
        {{/options }}
      </select>
    </div>
  """
})
