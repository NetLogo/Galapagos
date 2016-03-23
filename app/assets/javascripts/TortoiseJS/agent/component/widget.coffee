window.RactiveWidget = Ractive.extend({

  data: -> {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # Widget
  }

  isolated: true

})
