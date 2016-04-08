window.RactiveEditFormDropdown = Ractive.extend({

  data: -> {
    choices:  undefined # Array[String]
  , id:       undefined # String
  , label:    undefined # String
  , selected: undefined # String
  }

  isolated: true

  twoway: false

  template:
    """
    <label for="{{id}}">{{label}}</label>
    <select id="{{id}}" name="boxtype" class="widget-edit-dropdown">
      {{#choices}}
        <option value="{{this}}"{{# this === selected }} selected{{/}}>{{this}}</option>
      {{/}}
    </select>
    """

})
