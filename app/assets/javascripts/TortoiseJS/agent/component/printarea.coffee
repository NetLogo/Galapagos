window.RactivePrintArea = Ractive.extend({

  data: {
    id:     undefined # String
  , output: undefined # String
  }

  isolated: true

  oninit: ->
    @observe('output', ->
      @update('output').then(=>
        outputElem = @find("#" + @get("id"))
        outputElem?.scrollTop = outputElem.scrollHeight
      )
    )

  template:
    """
    <pre id='{{id}}' class='netlogo-output-area'>{{output}}</pre>
    """

})
