RactiveEditFormLabeledInput = Ractive.extend({

  data: -> {
    attrs:       undefined # String
  , checked:     undefined # Boolean
  , class:       undefined # String
  , divClass:   "flex-row" # String
  , id:          undefined # String
  , labelStr:    undefined # String
  , labelStyle:  undefined # String
  , max:         undefined # Number
  , min:         undefined # Number
  , name:        undefined # String
  , onChange:    undefined # String
  , onInput:     undefined # (Context) => Boolean
  , placeholder: undefined # String
  , required:    undefined # Boolean
  , style:       undefined # String
  , type:        undefined # String
  , value:       undefined # Any
  }

  twoway: false

  on: {

    # (Context) => Unit
    'exec': (context) ->
      event = @get('onChange')
      if (event)
        if (@get('type') is 'number')
          @set('value', @clampNumber(@get('value'), @get('min'), @get('max')))
        @fire(event, context, @get('value'))
      return

    # (Context) => Boolean
    'process-input': (context) ->
      @get("onInput")?(context)

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
        <input class="widget-edit-text widget-edit-input {{ class }}"
          type="{{ type }}" name="{{ name }}" style="{{ style }}"
          value="{{ value }}" checked="{{ checked }}"
          {{#if id}}id="{{ id }}"{{/if}}
          {{#if placeholder}}placeholder="{{ placeholder }}"{{/if}}
          {{#if min}}min="{{ min }}"{{/if}} {{#if max}}max="{{ max }}"{{/if}}
          on-change="exec" on-input="process-input"
          {{ attrs }} />
      </div>
    </div>
    """

})

RactiveTwoWayLabeledInput = RactiveEditFormLabeledInput.extend({

  data: -> {
    attrs: 'lazy step="any"'
  }

  twoway: true

})

export {
  RactiveEditFormLabeledInput,
  RactiveTwoWayLabeledInput,
}
