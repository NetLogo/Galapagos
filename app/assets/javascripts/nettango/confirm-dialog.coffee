window.RactiveConfirmDialog = Ractive.extend({

  data: () -> {
      active:         false # Boolean
    , text:           null  # String
    , approveText:    null  # String
    , approveEvent:   null  # String
    , denyText:       null  # String
    , denyEvent:      null  # String
    , eventArguments: null  # Array[Any]
    , eventTarget:    null  # Ractive
  }

  # (ShowOptions) => Unit
  show: (options) ->
    @set("active",         true)
    @set("text",           options?.text ? "Are you sure?")
    @set("approveText",    options?.approve?.text ? "Yes")
    @set("approveEvent",   options?.approve?.event)
    @set("denyText",       options?.deny?.text ? "No")
    @set("denyEvent",      options?.deny?.event)
    @set("eventArguments", options?.eventArguments)
    @set("eventTarget",    options?.eventTarget)
    return

  on: {
    # (Event, String) => Unit
    'fire-event': (_, eventId) ->
      @set("active", false)
      eventName = @get(eventId)
      if (eventName)
        args        = @get("eventArguments") ? []
        eventTarget = @get("eventTarget") ? this
        eventTarget.fire(eventName, ...args)
      return
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-dialog-overlay" {{# !active }}hidden{{/}}>
      <div class="ntb-confirm-dialog">
        <div class="ntb-confirm-header">Confirm</div>
        <div class="ntb-confirm-text">{{ text }}</div>
        <input class="widget-edit-text ntb-confirm-button" type="button" on-click="[ 'fire-event', 'approveEvent' ]" value="{{ approveText }}">
        <input class="widget-edit-text ntb-confirm-button" type="button" on-click="[ 'fire-event', 'denyEvent' ]" value="{{ denyText }}">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})
