window.RactiveErrorDisplay = Ractive.extend({
  data: () -> {
      active:  false # Boolean
    , message: ""    # String
  }

  # String => Unit
  show: (message) ->
    @set("message", message)
    @set("active",  true)
    return

  on: {
    # () => Unit
    'hide-alert': () ->
      @set("active", false)
      return
  }

  template: """
    <div class="ntb-error-overlay" {{# !active }}hidden{{/}}>
      <div class="widget-edit-popup widget-edit-text ntb-error-content">
        <div>{{ message }}</div>
        <input class="widget-edit-text" type="button" on-click="hide-alert" value="Close">
      </div>
    </div>
  """
})
