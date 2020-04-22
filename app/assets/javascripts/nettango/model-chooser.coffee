window.RactiveModelChooser = Ractive.extend({

  data: () -> {
      active:      false # Boolean
    , runtimeMode: "dev" # String
    , playMode:    false # Boolean
    , top:         "50px" # String
    , encodedUrl:  undefined # String
    , name:        undefined # String
  }

  # (ShowOptions) => Unit
  show: (top = "50px") ->
    @set("active",     true)
    @set("top",        top)
    @set("encodedUrl", null)
    @set("name",       null)
    return

  on: {
    'complete': (_) ->
      modelList  = @find("#tortoise-model-list")

      hostPrefix = "#{window.location.protocol}//#{window.location.host}"

      pickModel = (path, name) =>
        encodedUrl = encodeURI(hostPrefix + '/assets/' + path)
        @set("encodedUrl", encodedUrl)
        @set("name", name)
        return

      onComplete = () ->
        return

      if (not @get("playMode"))
        exports.bindModelChooser(modelList, onComplete, pickModel, @get("runtimeMode"))

      return

    # (Event, String) => Unit
    'load-model': (_, eventId) ->
      @set("active", false)
      @fire("ntb-load-nl-url", @get("encodedUrl"), @get("name"))
      return

    'cancel': () ->
      @set("active", false)
      return

  }

  template:
    # coffeelint: disable=max_line_length
    """
    <div class="ntb-dialog-overlay" {{# !active }}hidden{{/}}>
      <div class="ntb-confirm-dialog" style="margin-top: {{ top }}">
        <div class="ntb-confirm-header">Choose a Library Model</div>
        <div class="ntb-confirm-text">
          <span>Pick a NetLogo model from the NetLogo models library to use with your NetTango project.</span>
          <div class="ntb-netlogo-model-chooser">
            <span id="tortoise-model-list" class="model-list tortoise-model-list"></span>
          </div>
        </div>
        <input class="widget-edit-text ntb-confirm-button" type="button" on-click="load-model" value="Load the model">
        <input class="widget-edit-text ntb-confirm-button" type="button" on-click="cancel" value="Cancel">
      </div>
    </div>
    """
    # coffeelint: enable=max_line_length
})
