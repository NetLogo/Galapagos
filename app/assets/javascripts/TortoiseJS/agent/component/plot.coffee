window.RactivePlot = RactiveWidget.extend({

  template:
    """
    <div id="{{id}}"
         on-contextmenu="@this.fire('showContextMenu', @event, id + '-context-menu')"
         class="netlogo-widget netlogo-plot"
         style="{{dims}}"></div>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="@this.fire('deleteWidget', id, id + '-context-menu', widget.id)">Delete</li>
      </ul>
    </div>
    """

})
