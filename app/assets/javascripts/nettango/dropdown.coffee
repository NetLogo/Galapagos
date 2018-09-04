window.RactiveDropdown = Ractive.extend({

  data: () -> {
    style:       undefined # String
    id:          undefined # String
    value:       undefined # Any
    label:       undefined # String
    options:     undefined # Array[String]
    changeEvent: undefined # String
  }

  template:
    """
    <div style="flex: column; padding: 0px;{{ style }}">
      <label for="{{ id }}">{{ label }}</label>
      <select id="{{ id }}" value="{{ value }}" style="margin: 6px; font-size: 16pt;" on-change="changed" >
        {{#options }}
          <option>{{ this }}</option>
        {{/options }}
      </select>
    </div>
    """
})
