window.RactivePlot = Ractive.extend({
  data: {
    dims:   undefined # String
  , widget: undefined # PlotWidget
  }

  isolated: true

  template:
    """
    <div class="netlogo-widget netlogo-plot netlogo-plot-{{widget.plotNumber}}"
         style="{{dims}}"></div>
    """

})
