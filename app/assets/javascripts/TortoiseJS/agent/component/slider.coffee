window.RactiveSlider = Ractive.extend({
  data: {
    dims:       undefined # String
  , id:         undefined # String
  , widget:     undefined # SliderWidget
  , errorClass: undefined # String
  }

  isolated: true

  template:
    """
    <label id="{{id}}"
           class="netlogo-widget netlogo-slider netlogo-input {{errorClass}}"
           style="{{dims}}">
      <input type="range"
             max="{{widget.maxValue}}" min="{{widget.minValue}}"
             step="{{widget.step}}" value="{{widget.currentValue}}" />
      <div class="netlogo-slider-label">
        <span class="netlogo-label" on-click="showErrors">{{widget.display}}</span>
        <span class="netlogo-slider-value">
          <input type="number"
                 style="width: {{widget.currentValue.toString().length + 3.0}}ch"
                 min={{widget.minValue}} max={{widget.maxValue}}
                 value={{widget.currentValue}} step={{widget.step}} />
          {{#widget.units}}{{widget.units}}{{/}}
        </span>
      </div>
    </label>
    """

})
