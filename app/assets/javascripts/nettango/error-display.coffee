window.RactiveErrorDisplay = Ractive.extend({
  data: () -> {
      active:     false # Boolean
    , message:    ""    # String
    , stackTrace: null  # String
  }

  # String => Unit
  show: (message, stackTrace) ->
    @set("active", true)
    @set("message", message)
    @set("stackTrace", stackTrace)
    return

  on: {
    # () => Unit
    'hide-alert': () ->
      @set("active", false)
      return
  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-error-overlay" {{# !active }}hidden{{/}}>
      <div class="widget-edit-popup widget-edit-text ntb-error-content">
        <div class="ntb-error-message">
          An error occurred. {{{ message }}}
        </div>
        {{# stackTrace }}
          <p class="ntb-error-stack-label">Advanced users might find the generated error helpful, which is as follows:</p>
          <textarea class="ntb-error-stack" readonly value="{{ stackTrace }}" />
        {{/stackTrace }}
        <input class="widget-edit-text" type="button" on-click="hide-alert" value="Close">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})
