window.RactivePrintArea = Ractive.extend({

  data: -> {
    fontSize: undefined # Number
  , id:       undefined # String
  , output:   undefined # String
  }

  oninit: ->
    @observe('output', ->
      @update('output').then(=>
        outputElem = @find("#" + @get("id"))
        outputElem?.scrollTop = outputElem.scrollHeight
      )
    )

  template:
    """
    <pre id='{{id}}' class='netlogo-output-area'
         style="font-size: {{fontSize}}px;">{{output}}</pre>
    """

})
