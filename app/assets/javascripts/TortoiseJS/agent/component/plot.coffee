window.RactivePlot = Ractive.extend({
  data: {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # PlotWidget
  }

  isolated: true

  template:
    """
    <div id="{{id}}"
         class="netlogo-widget netlogo-plot"
         style="{{dims}}"></div>
    """

})
