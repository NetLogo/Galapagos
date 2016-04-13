window.RactiveEditFormFontSize = Ractive.extend({

  data: -> {
    id:    undefined # String
  , name:  undefined # String
  , value: undefined # String
  }

  isolated: true

  twoway: false

  template:
    """
    <label for="{{id}}">Font size: </label>
    <input id="{{id}}" class="widget-edit-text-size" name="{{name}}" placeholder="(Required)"
           type="number" value="{{value}}" autofocus min=1 max=128 step=1 required />
    """

})
