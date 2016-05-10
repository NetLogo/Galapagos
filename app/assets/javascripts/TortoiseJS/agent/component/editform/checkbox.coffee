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
      <input id="{{id}}" class="widget-edit-checkbox"
             name="[[name]]" type="checkbox" checked="{{isChecked}}" />
      <label for="{{id}}" class="widget-edit-input-label">{{labelText}}</label>
    </div>
    """

})
