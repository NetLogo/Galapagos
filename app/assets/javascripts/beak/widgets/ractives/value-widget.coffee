import RactiveWidget from "./widget.js"

RactiveValueWidget = RactiveWidget.extend({
  data: () -> {
    oldValue:      undefined # Any
    internalValue: undefined # Any
  }

  widgetType: undefined # String

  observe: {
    'widget.currentValue': (newValue, oldValue) ->
      if oldValue isnt newValue
        @set('internalValue', newValue)
        @set(     'oldValue', newValue)
      return
  }

  on: {

    'init': () ->
      currentValue = @get('widget.currentValue')
      @set('internalValue', currentValue)
      @set(     'oldValue', currentValue)
      return

    'widget-value-change': (_, args...) ->
      newValue = @get('internalValue')
      oldValue = @get('oldValue')
      if oldValue isnt newValue
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
