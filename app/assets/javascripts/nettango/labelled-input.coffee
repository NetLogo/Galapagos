window.RactiveLabelledInput = Ractive.extend({
  on: {
    'exec': (_) ->
      if (@get('type') is 'number')
        value = @get('value')
        min = @get('min')
        max = @get('max')
        value = if (min? and value < min)
          min
        else if (max? and value > max)
          max
        else
          value
        @set('value', value)
      event = @get('onChange')
      @fire(event, _)
  }
  data: () -> {
    style:    undefined # String
    id:       undefined # String
    value:    undefined # Any
    type:     undefined # String
    name:     undefined # String
    label:    undefined # String
    onChange: undefined # String
    min:      undefined # Number
    max:      undefined # Number
  }

  template:
    """
    <div style="flex: column; padding: 0px;{{ style }}">
      <label for="{{ id }}">{{ label }}</label>
      <input id="{{ id }}" name="{{ name }}" type="{{ type }}" value="{{ value }}" min="{{ min }}" max="{{ max }}"
        class="widget-edit-inputbox" style="margin: 0px; width: 90%; min-width: 30px;" lazy
        on-change="exec"
        >
    </div>
    """
})
