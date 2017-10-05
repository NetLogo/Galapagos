window.RactiveEditFormCheckbox = Ractive.extend({

  data: -> {
    disabled:  undefined # Boolean
  , id:        undefined # String
  , isChecked: undefined # Boolean
  , labelText: undefined # String
  , name:      undefined # String
  }

  twoway: false

  template:
    """
    <div>
      <input id="{{id}}" class="widget-edit-checkbox"
             name="[[name]]" type="checkbox" checked="{{isChecked}}"
             {{# disabled === true }} disabled {{/}} />
      <label for="{{id}}" class="widget-edit-input-label">{{labelText}}</label>
    </div>
    """

})
