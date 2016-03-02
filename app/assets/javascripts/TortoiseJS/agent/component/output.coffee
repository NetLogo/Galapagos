window.RactiveOutputArea = Ractive.extend({
  data: {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # OutputWidget
  , output: undefined # String
  }

  isolated: true

  oninit: ->
    @observe('output', ->
      @update('output').then(=>
        outputElem = @find('.netlogo-output-area')
        outputElem?.scrollTop = outputElem.scrollHeight
      )
    )

  template:
    """
    <div id="{{id}}"
         class="netlogo-widget netlogo-output netlogo-output-widget" style="{{dims}}">
      <pre class='netlogo-output-area'>{{output}}</pre>
    </div>
    """

})
