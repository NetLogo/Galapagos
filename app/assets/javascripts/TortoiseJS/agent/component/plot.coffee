window.RactivePlot = RactiveWidget.extend({

  data: -> {
    contextMenuOptions: [@standardOptions(this).deleteAndRecompile]
  }

  # coffeelint: disable=max_line_length
  template:
    """
    <div id="{{id}}"
         on-contextmenu="@this.fire('showContextMenu', @event)" on-click="@this.fire('selectWidget', @event)"
         {{ #isEditing }} draggable="true" on-drag="dragWidget" on-dragstart="startWidgetDrag" on-dragend="stopWidgetDrag" {{/}}
         class="netlogo-widget netlogo-plot{{#isEditing}} interface-unlocked{{/}}"
         style="{{dims}}z-index: {{3200 - this.widget.top}};{{ #isEditing }}padding: 10px;{{/}}"></div>
    """
  # coffeelint: enable=max_line_length

})
