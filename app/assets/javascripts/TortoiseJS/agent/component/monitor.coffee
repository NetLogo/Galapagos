window.RactiveMonitor = Ractive.extend({
  data: {
    dims:       undefined # String
  , id:         undefined # String
  , widget:     undefined # MonitorWidget
  , errorClass: undefined # String
  }

  isolated: true

  template:
    """
    <div id="{{id}}"
         class="netlogo-widget netlogo-monitor netlogo-output"
         style="{{dims}} font-size: {{widget.fontSize}}px;">
      <label class="netlogo-label {{errorClass}}" on-click=\"showErrors\">{{widget.display || widget.source}}</label>
      <output class="netlogo-value">{{widget.currentValue}}</output>
    </div>
    """

})
