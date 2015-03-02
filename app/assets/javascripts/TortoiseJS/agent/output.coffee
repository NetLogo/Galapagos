window.OutputArea = Ractive.extend({
  data: { output: '' }

  isolated: true

  oninit: ->
    @observe('output', ->
      @update('output').then(=>
        outputElem = @find('.netlogo-output-area')
        outputElem?.scrollTop = outputElem.scrollHeight
      )
    )

  template: "<pre class='netlogo-output-area'>{{output}}</pre>"
})
