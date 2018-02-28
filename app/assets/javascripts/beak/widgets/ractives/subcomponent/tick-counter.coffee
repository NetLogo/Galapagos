window.RactiveTickCounter = Ractive.extend({

  data: -> {
    isVisible: undefined # Boolean
  , label:     undefined # String
  , value:     undefined # Number
  }

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
