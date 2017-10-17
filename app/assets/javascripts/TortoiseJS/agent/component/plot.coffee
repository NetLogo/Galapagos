window.RactivePlot = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).deleteAndRecompile]
  }

  template:
    """
    <div id="{{id}}"
         on-contextmenu="@this.fire('showContextMenu', @event)"
         class="netlogo-widget netlogo-plot"
         style="{{dims}}z-index: {{3200 - this.widget.top}};"></div>
    """

})
