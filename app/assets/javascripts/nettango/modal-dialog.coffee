RactiveModelDialog = Ractive.extend({

  data: () -> {
    active:         false # Boolean
  , left:           300   # Int
  , top:            50    # Int
  , text:           null  # String
  , approveText:    null  # String
  , approveEvent:   null  # String
  , denyText:       null  # String
  , denyEvent:      null  # String
  , eventArguments: null  # Array[Any]
  , eventTarget:    null  # Ractive
  }

  # (ShowOptions, Int, Int) => Unit
  show: (options, left = 300, top = 50) ->
    @set("active",         true)
    @set("left",           left)
    @set("top",            top)
    @set("text",           options?.text           ? "Are you sure?")
    @set("approveText",    options?.approve?.text  ? "Yes")
    @set("approveEvent",   options?.approve?.event)
    @set("denyText",       options?.deny?.text     ? "No")
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
    <div class="ntb-dialog-overlay ntb-confirm-overlay" {{# !active }}hidden{{/}}>
      <div class="ntb-dialog" style="left: {{left}}px; top: {{top}}px;">
        <div class="ntb-dialog-header">Confirm</div>
        {{> dialogContent }}
        <input class="widget-edit-text ntb-dialog-button" type="button" on-click="[ 'fire-event', 'approveEvent' ]" value="{{ approveText }}">
        <input class="widget-edit-text ntb-dialog-button" type="button" on-click="[ 'fire-event', 'denyEvent' ]" value="{{ denyText }}">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveModelDialog
