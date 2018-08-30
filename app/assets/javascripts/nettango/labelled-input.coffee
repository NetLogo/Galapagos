window.RactiveLabelledInput = Ractive.extend({

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

  on: {
    # (Context) => Unit
    'exec': (context) ->
      if (@get('type') is 'number')
        @set('value', @clampNumber(@get('value'), @get('min'), @get('max')))
      event = @get('onChange')
      @fire(event, context)
      return
  }

  # (Number, Number, Number) => Number
  clampNumber: (value, min, max) ->
    if (min? and value < min)
      min
    else if (max? and value > max)
      max
    else
      value

  template:
    """
    <div style="flex: column; padding: 0px;{{ style }}">
      <label for="{{ id }}">{{ label }}</label>
      <input id="{{ id }}" name="{{ name }}" type="{{ type }}" value="{{ value }}" min="{{ min }}" max="{{ max }}"
        class="widget-edit-inputbox" style="margin: 0px; width: 90%; min-width: 30px;" lazy step="any"
        on-change="exec"
        >
    </div>
    """
})
