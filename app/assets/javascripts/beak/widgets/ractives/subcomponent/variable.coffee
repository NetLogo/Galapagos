window.RactiveEditFormVariable = Ractive.extend({

  data: -> {
    id:    undefined # String
  , name:  undefined # String
  , value: undefined # String
  }

  twoway: false

  on: {
    validate: ({ node }) ->
      varName     = node.value.toLowerCase()
      validityStr =
        if window.keywords.all.some((kw) -> kw.toLowerCase() is varName)
          "'#{node.value}' is a reserved name"
        else
          ""
      node.setCustomValidity(validityStr)
      false
  }

  # coffeelint: disable=max_line_length
  template:
    """
    <label for="{{id}}">Global variable: </label>
    <input id="{{id}}" class="widget-edit-text" name="{{name}}" placeholder="(Required)"
           type="text" value="{{value}}"
           autofocus autocomplete="off" on-input="validate"
           pattern="[=*!<>:#+/%'&$^.?\\-_a-zA-Z][=*!<>:#+/%'&$^.?\\-\\w]*"
           title="One or more alphanumeric characters and characters in (( $^.?=*!<>:#+/%'&-_ )).  Cannot start with a number"
           required />
    """
  # coffeelint: enable=max_line_length

})
