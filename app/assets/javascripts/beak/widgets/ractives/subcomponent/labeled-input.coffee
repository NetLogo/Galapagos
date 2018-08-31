window.RactiveEditFormLabeledInput = Ractive.extend({

  data: -> {
    attrs:      undefined # String
  , class:      undefined # String
  , divClass:  "flex-row" # String
  , id:         undefined # String
  , labelStr:   undefined # String
  , labelStyle: undefined # String
  , max:        undefined # Number
  , min:        undefined # Number
  , name:       undefined # String
  , onChange:   undefined # String
  , style:      undefined # String
  , type:       undefined # String
  , value:      undefined # Any
  }

  twoway: false

  on: {
    # (Context) => Unit
    'exec': (context) ->
      event = @get('onChange')
      if (event)
        if (@get('type') is 'number')
          @set('value', @clampNumber(@get('value'), @get('min'), @get('max')))
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
    <div class="{{ divClass }}">
      <label for="{{ id }}" class="widget-edit-input-label" style="{{ labelStyle }}">{{ labelStr }}</label>
      <div style="flex-grow: 1;">
        <input class="widget-edit-text widget-edit-input {{ class }}" id="{{ id }}" name="{{ name }}"
          min="{{ min }}" max="{{ max }}" on-change="exec"
          type="{{ type }}" value="{{ value }}" style="{{ style }}" {{ attrs }} />
      </div>
    </div>
    """

})

window.RactiveTwoWayLabeledInput = RactiveEditFormLabeledInput.extend({

  data: -> {
    attrs: 'lazy step="any"'
  }

  twoway: true

})
