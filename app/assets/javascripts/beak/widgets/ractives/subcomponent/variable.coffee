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
           pattern="[=*!<>:#+/%'&$^.?\\-_a-zA-Z][=*!<>:#+/%'&$^.?\\-\\w]*"
           title="A variable name to be used for the switch's value in your model.

Must contain at least one valid character.  Valid characters are alphanumeric characters and all the special characters in (( $^.?=*!<>:#+/%'&-_ )), but cannot start with a number."
           required />
    """
  # coffeelint: enable=max_line_length

})
