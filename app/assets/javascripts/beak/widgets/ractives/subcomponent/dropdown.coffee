window.RactiveEditFormDropdown = Ractive.extend({

  data: -> {
    changeEvent: undefined # String
  , choices:     undefined # Array[String]
  , disableds:   undefined # Array[String]
  , name:        undefined # String
  , id:          undefined # String
  , label:       undefined # String
  , selected:    undefined # String

  , checkIsDisabled: (item) -> (@get('disableds') ? []).indexOf(item) isnt -1

  }

  on: {
    # (Context) => Unit
    '*.changed': (_) ->
      event = @get('changeEvent')
      if (event?)
        @fire(event)
      return
  }

  twoway: false

  template:
    """
    <div class="{{ divClass }}">
      <label for="{{ id }}" class="widget-edit-input-label">{{ label }}</label>
      <select id="{{ id }}" name="{{ name }}" class="widget-edit-dropdown" value="{{ selected }}">
        {{#choices }}
          <option value="{{ this }}" {{# checkIsDisabled(this) }} disabled {{/}}>{{ this }}</option>
        {{/}}
      </select>
    </div>
    """

})

window.RactiveTwoWayDropdown = window.RactiveEditFormDropdown.extend({ twoway: true })
