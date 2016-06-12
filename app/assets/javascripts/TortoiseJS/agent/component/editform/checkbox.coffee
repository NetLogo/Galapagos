window.RactiveEditFormCheckbox = Ractive.extend({

  data: -> {
    id:        undefined # String
  , isChecked: undefined # Boolean
  , labelText: undefined # String
  , name:      undefined # String
  }

  isolated: true

  twoway: false

  template:
    """
    <div>
      <input id="{{id}}" class="widget-edit-checkbox" style="height: 13px;"
             name="{{name}}" type="checkbox"{{#isChecked}} checked{{/}} />
      <label for="{{id}}">{{labelText}}</label>
    </div>
    """

})
