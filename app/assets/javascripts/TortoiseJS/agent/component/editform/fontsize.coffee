window.RactiveEditFormFontSize = RactiveEditFormLabeledInput.extend({

  data: -> {
    attrs:    "min=0 step=1 required"
  , labelStr: "Font size:"
  , style:    "width: 70px;"
  , type:     "number"
  }

  twoway: false

})
