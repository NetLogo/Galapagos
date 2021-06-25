id = -1
nextId = () ->
  id = id + 1
  id

RactiveModalDialog = Ractive.extend({

  # type EventOptions = {
  #     text: String
  #   , event: String | null
  #   , target: Ractive | null
  #   , arguments: Any[] | null
  #   , argsMaker: () => Any[] | null
  # }

  data: () -> {
    id:               nextId()
  , active:           false           # Boolean
  , preRenderContent: false           # Boolean
  , top:              50              # Int
  , approve:          { text: "Yes" } # EventOptions
  , deny:             { text: "No"  } # EventOptions
  }

  # () => Unit
  show: () ->
    @set("active", true)
    deny = @find("#ntb-#{@get('id')}-deny-button")
    deny.focus()
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

    'check-escape': ({ event: { key } }) ->
      if key is "Escape"
        @fire("fire-event", {}, 'deny')
      return
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-dialog-overlay {{extraClasses}}" {{# !active }}hidden{{/}} on-keyup="check-escape">
      <div class="ntb-dialog" style="top: {{top}}px;">
        {{# active || preRenderContent }}
        <div class="ntb-dialog-header">
          {{> headerContent }}
        </div>
        <div class="ntb-dialog-content">
          {{> dialogContent }}
        </div>
        {{/}}
        <div class="ntb-dialog-buttons">
          <input
            id="ntb-{{id}}-approve-button"
            class="widget-edit-text ntb-dialog-button"
            type="button"
            on-click="[ 'fire-event', 'approve' ]"
            value="{{ approve.text }}"
            >
          <input
            id="ntb-{{id}}-deny-button"
            class="widget-edit-text ntb-dialog-button"
            type="button"
            on-click="[ 'fire-event', 'deny' ]"
            value="{{ deny.text }}"
            >
        </div>
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})

export default RactiveModalDialog
