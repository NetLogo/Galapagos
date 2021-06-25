RactiveModelDialog = Ractive.extend({

  # type EventOptions = {
  #     text: String
  #   , event: String | null
  #   , target: Ractive | null
  #   , arguments: Any[] | null
  #   , argsMaker: () => Any[] | null
  # }

  data: () -> {
    active:           false           # Boolean
  , preRenderContent: false           # Boolean
  , top:              50              # Int
  , approve:          { text: "Yes" } # EventOptions
  , deny:             { text: "No"  } # EventOptions
  }

  # () => Unit
  show: () ->
    @set("active", true)
    return

  on: {
    # (Event, String) => Unit
    'fire-event': (_, eventId) ->
      @set("active", false)
      eventOptions = @get(eventId)
      if eventOptions? and eventOptions.event?
        args   = eventOptions.arguments ? eventOptions.argsMaker?() ? []
        target = eventOptions.target ? this
        target.fire(eventOptions.event, ...args)
      return
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-dialog-overlay ntb-confirm-overlay" {{# !active }}hidden{{/}}>
      <div class="ntb-dialog" style="top: {{top}}px;">
        {{# active || preRenderContent }}
        <div class="ntb-dialog-header">
          {{> headerContent }}
        </div>
        <div class="ntb-dialog-content">
          {{> dialogContent }}
        </div>
        {{/}}
        <input class="widget-edit-text ntb-dialog-button" type="button" on-click="[ 'fire-event', 'approve' ]" value="{{ approve.text }}">
        <input class="widget-edit-text ntb-dialog-button" type="button" on-click="[ 'fire-event', 'deny' ]" value="{{ deny.text }}">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveModelDialog
