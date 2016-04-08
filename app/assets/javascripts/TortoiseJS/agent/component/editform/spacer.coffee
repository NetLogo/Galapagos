window.RactiveEditFormSpacer = Ractive.extend({

  data: -> {
    height: undefined # String
  }

  isolated: true

  twoway: false

  template:
    """
    <div style="height: {{height}};"></div>
    """

})
