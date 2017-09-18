window.RactiveEditFormVariable = Ractive.extend({

  data: -> {
    id:    undefined # String
  , name:  undefined # String
  , value: undefined # String
  }

  twoway: false

  # coffeelint: disable=max_line_length
  template:
    """
    <label for="{{id}}">Global variable: </label>
    <input id="{{id}}" class="widget-edit-text" name="{{name}}" placeholder="(Required)"
           type="text" value="{{value}}"
           autofocus autocomplete="off"
           pattern="[=*!<>:#+/%'&$^.?\\-\\w]+"
           title="A variable name to be used for the switch's value in your model.

Must contain at least one valid character.  Valid characters are alphanumeric characters and all of the following special characters: $^.?=*!<>:#+/%'&-_"
           required />
    """
  # coffeelint: enable=max_line_length

})
