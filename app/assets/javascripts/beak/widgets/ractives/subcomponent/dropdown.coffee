RactiveEditFormDropdown = Ractive.extend({

  data: -> {
    changeEvent: undefined # String
  , choices:     undefined # Array[String | { value: String, text: String }]
  , disableds:   undefined # Array[String]
  , name:        undefined # String
  , id:          undefined # String
  , label:       undefined # String
  , selected:    undefined # String

  , checkIsDisabled: (item) ->
    disableds = @get('disableds') ? []
    disableds.some( (d) -> d is item or item.value? and item.value is d )

  , valOf: (item) ->
    if item.value? then item.value else item

  , textOf: (item) ->
    if item.text? then item.text else item

  }

  on: {
    # (Context) => Unit
    '*.changed': (context) ->
      event = @get('changeEvent')
      if (event?)
        @fire(event)
      else
        @fire('dropdown-changed', context.event.target.value)
      return
  }

  twoway: false

  template:
    """
    <div class="{{ divClass }}">
      <label for="{{ id }}" class="widget-edit-input-label">{{ label }}</label>
      <select id="{{ id }}" name="{{ name }}" class="widget-edit-dropdown" value="{{ selected }}" on-change="changed">
        {{#choices }}
          <option value="{{ valOf(this) }}" {{# checkIsDisabled(this) }} disabled {{/}}>{{ textOf(this) }}</option>
        {{/}}
      </select>
    </div>
    """

})

RactiveTwoWayDropdown = RactiveEditFormDropdown.extend({ twoway: true })

export {
  RactiveEditFormDropdown,
  RactiveTwoWayDropdown,
}
