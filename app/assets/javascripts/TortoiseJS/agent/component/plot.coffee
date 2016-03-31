window.RactivePlot = Ractive.extend({
  data: -> {
    dims:   undefined # String
  , id:     undefined # String
  , widget: undefined # PlotWidget
  }

  isolated: true

  template:
    """
    <div id="{{id}}"
         on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
         class="netlogo-widget netlogo-plot"
         style="{{dims}}"></div>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
      </ul>
    </div>
    """

})
