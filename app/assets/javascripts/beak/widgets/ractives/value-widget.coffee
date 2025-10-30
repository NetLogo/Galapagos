import RactiveWidget from "./widget.js"

RactiveValueWidget = RactiveWidget.extend({
  data: () -> {
    oldValue:      undefined # Any
    internalValue: undefined # Any
  }
  # coffeelint: enable=max_line_length

  widgetType: undefined # String

  on: {
    'init': () ->
      resetValuesToCurrent = () =>
        currentValue = @get('widget.currentValue')
        @set('internalValue', currentValue)
        @set('oldValue',      currentValue)
        return

      @observe('widget.currentValue', resetValuesToCurrent)
      resetValuesToCurrent()
      return

    'widget-value-change': (_, args...) ->
      newValue = @get('internalValue')
      oldValue = @get('oldValue')
      if (oldValue isnt newValue)
        @set('widget.currentValue', newValue)
        widget = @get('widget')
        @fire("#{@widgetType}-widget-changed", widget.id, widget.variable, newValue, oldValue, args...)
      return

    'paste-into-current-value': ->
      widget = @get('widget')
      try
        text = await navigator.clipboard.readText()
        @fire('update-widget-value-from-string', text)
      catch error
        alert("Failed to read from clipboard: " + error)
      return
  }

  # (Widget) => Array[Any]
  getExtraNotificationArgs: () ->
    widget = @get('widget')
    [widget.variable]

})

export default RactiveValueWidget
