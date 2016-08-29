window.RactiveTickCounter = Ractive.extend({

  data: -> {
    isVisible: undefined # Boolean
  , label:     undefined # String
  , value:     undefined # Number
  }

  isolated: true

  twoway: false

  template:
    """
    <span class="netlogo-label">
      {{ # isVisible }}
        {{label}}: {{value}}
      {{else}}
        &nbsp;
      {{/}}
    </span>
    """

})
