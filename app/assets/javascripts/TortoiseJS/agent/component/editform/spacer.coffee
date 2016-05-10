window.RactiveEditFormSpacer = Ractive.extend({

  data: -> {
    height: undefined # String
  , width:  undefined # String
  }

  isolated: true

  template:
    """
    <div style="{{>height}} {{>width}}"></div>
    """

  partials: {
    height: "{{ #height }}height: {{height}};{{/}}"
    width:  "{{ #width  }}width:  {{width }};{{/}}"
  }

})
