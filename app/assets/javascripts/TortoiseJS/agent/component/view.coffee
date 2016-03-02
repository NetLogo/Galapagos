window.RactiveView = Ractive.extend({
  data: {
    dims:   undefined # String
  , widget: undefined # ViewWidget
  , ticks:  undefined # String
  }

  isolated: true

  template:
    """
    <div class="netlogo-widget netlogo-view-container"
         style="{{dims}}">
      <div class="netlogo-widget netlogo-tick-counter">
        {{# widget.showTickCounter }}
          {{widget.tickCounterLabel}}: <span>{{ticks}}</span>
        {{/}}
      </div>
    </div>
    """

})
