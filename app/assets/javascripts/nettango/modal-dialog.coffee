RactiveModelDialog = Ractive.extend({

  data: () -> {
    active:           false # Boolean
  , preRenderContent: false # Boolean
  , left:             300   # Int
  , top:              50    # Int
  , approveText:      null  # String
  , approveEvent:     null  # String
  , denyText:         null  # String
  , denyEvent:        null  # String
  , eventArguments:   null  # Array[Any]
  , eventTarget:      null  # Ractive
  }

  # (ShowOptions) => Unit
  show: (options) ->
    @set("active",           true)
    @set("left",             options?.left             ? 300)
    @set("top",              options?.top              ? 50)
    @set("approveText",      options?.approve?.text    ? "Yes")
    @set("approveEvent",     options?.approve?.event)
    @set("denyText",         options?.deny?.text       ? "No")
    @set("denyEvent",        options?.deny?.event)
    @set("eventArguments",   options?.eventArguments)
    @set("eventArgsMaker",   options?.eventArgsMaker)
    @set("eventTarget",      options?.eventTarget)
    return

  on: {
    # (Event, String) => Unit
    'fire-event': (_, eventId) ->
      @set("active", false)
      eventName = @get(eventId)
      if (eventName)
        args        = @get("eventArguments") ? @get("eventArgsMaker")?() ? []
        eventTarget = @get("eventTarget") ? this
        eventTarget.fire(eventName, ...args)
      return
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-dialog-overlay ntb-confirm-overlay" {{# !active }}hidden{{/}}>
      <div class="ntb-dialog" style="left: {{left}}px; top: {{top}}px;">
        {{# active || preRenderContent }}
        <div class="ntb-dialog-header">
          {{> headerContent }}
        </div>
        <div class="ntb-dialog-content">
          {{> dialogContent }}
        </div>
        {{/}}
        <input class="widget-edit-text ntb-dialog-button" type="button" on-click="[ 'fire-event', 'approveEvent' ]" value="{{ approveText }}">
        <input class="widget-edit-text ntb-dialog-button" type="button" on-click="[ 'fire-event', 'denyEvent' ]" value="{{ denyText }}">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveModelDialog
