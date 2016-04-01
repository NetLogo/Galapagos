window.RactiveLabel = RactiveWidget.extend({

  data: -> {
    convertColor: netlogoColorToCSS
  }

  isolated: true

  template:
    # Note that ">{{ display }}</pre>" thing is necessary. Since <pre> formats
    # text exactly as it appears, an extra space between the ">" and the
    # "{{ display }}" would result in an actual newline in the widget.
    # BCH 7/28/2015
    # coffeelint: disable=max_line_length
    """
    <pre id="{{id}}"
         on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
         class="netlogo-widget netlogo-text-box"
         style="{{dims}} font-size: {{widget.fontSize}}px; color: {{ convertColor(widget.color) }}; {{# widget.transparent}}background: transparent;{{/}}"
         >{{ widget.display }}</pre>
    <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
      <ul class="context-menu-list">
        <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
      </ul>
    </div>
    """
    # coffeelint: enable=max_line_length

})
