window.RactiveView = Ractive.extend({
  data: -> {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # ViewWidget
  , ticks:  undefined # String
  }

  isolated: true

  template:
    """
    <div id="{{id}}"
         on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
         class="netlogo-widget netlogo-view-container"
         style="{{dims}}">
      <div class="netlogo-widget netlogo-tick-counter">
        {{# widget.showTickCounter }}
          {{widget.tickCounterLabel}}: <span>{{ticks}}</span>
        {{/}}
      </div>
    </div>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      Nothing to see here...
    </div>
    """

})
