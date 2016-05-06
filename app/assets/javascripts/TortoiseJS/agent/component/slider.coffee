window.RactiveSlider = RactiveWidget.extend({

  data: -> {
    errorClass: undefined # String
  }

  isolated: true

  template:
    """
    {{>slider}}
    {{>contextMenu}}
    """

  partials: {

    slider:
      """
      <label id="{{id}}"
             on-contextmenu="showContextMenu:{{id + '-context-menu'}}"
             class="netlogo-widget netlogo-slider netlogo-input {{errorClass}}"
             style="{{dims}}">
        <input type="range"
               max="{{widget.maxValue}}" min="{{widget.minValue}}"
               step="{{widget.stepValue}}" value="{{widget.currentValue}}" />
        <div class="netlogo-slider-label">
          <span class="netlogo-label" on-click="showErrors">{{widget.display}}</span>
          <span class="netlogo-slider-value">
            <input type="number"
                   style="width: {{widget.currentValue.toString().length + 3.0}}ch"
                   min={{widget.minValue}} max={{widget.maxValue}}
                   value={{widget.currentValue}} step={{widget.stepValue}} />
            {{#widget.units}}{{widget.units}}{{/}}
          </span>
        </div>
      </label>
      """

    contextMenu:
      """
      <div id="{{id}}-context-menu" class="netlogo-widget-editor-menu-items">
        <ul class="context-menu-list">
          <li class="context-menu-item" on-click="deleteWidget:{{id}},{{id + '-context-menu'}},{{widget.id}}">Delete</li>
        </ul>
      </div>
      """

  }

})
