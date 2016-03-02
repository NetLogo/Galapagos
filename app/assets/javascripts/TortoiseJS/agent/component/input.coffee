window.RactiveInput = Ractive.extend({
  data: {
    dims:   undefined # String
  , widget: undefined # InputWidget
  }

  isolated: true

  template:
    """
    <label class="netlogo-widget netlogo-input-box netlogo-input"
           style="{{dims}}">
      <div class="netlogo-label">{{widget.varName}}</div>
      {{# widget.boxtype === 'Number'}}<input type="number" value="{{widget.currentValue}}" />{{/}}
      {{# widget.boxtype === 'String'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
      {{# widget.boxtype === 'String (reporter)'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
      {{# widget.boxtype === 'String (commands)'}}<input type="text" value="{{widget.currentValue}}" />{{/}}
      <!-- TODO: Fix color input. It'd be nice to use html5s color input. -->
      {{# widget.boxtype === 'Color'}}<input type="color" value="{{widget.currentValue}}" />{{/}}
    </label>
    """

})
