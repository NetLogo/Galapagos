window.RactiveMonitor = RactiveWidget.extend({

  data: -> {
    errorClass: undefined # String
  }

  isolated: true

  template:
    """
    <div id="{{id}}"
         on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
         class="netlogo-widget netlogo-monitor netlogo-output"
         style="{{dims}} font-size: {{widget.fontSize}}px;">
      <label class="netlogo-label {{errorClass}}" on-click=\"showErrors\">{{widget.display || widget.source}}</label>
      <output class="netlogo-value">{{widget.currentValue}}</output>
    </div>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
      </ul>
    </div>
    """

})
