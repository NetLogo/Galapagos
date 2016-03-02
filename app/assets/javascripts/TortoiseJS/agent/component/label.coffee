window.RactiveLabel = Ractive.extend({
  data: {
    dims:         undefined # String
  , widget:       undefined # LabelWidget
  , convertColor: netlogoColorToCSS
  }

  isolated: true

  template:
    # Note that ">{{ display }}</pre>" thing is necessary. Since <pre> formats
    # text exactly as it appears, an extra space between the ">" and the
    # "{{ display }}" would result in an actual newline in the widget.
    # BCH 7/28/2015
    # coffeelint: disable=max_line_length
    """
    <pre class="netlogo-widget netlogo-text-box"
         style="{{dims}} font-size: {{widget.fontSize}}px; color: {{ convertColor(widget.color) }}; {{# widget.transparent}}background: transparent;{{/}}"
         >{{ widget.display }}</pre>
    """
    # coffeelint: enable=max_line_length

})
