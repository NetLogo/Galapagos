import RactiveModelDialog from "./modal-dialog.js"
import { bindModelChooser } from "/models.js"

RactiveModelChooser = RactiveModelDialog.extend({

  data: () -> {
    runtimeMode: "dev" # String
  , encodedUrl:  undefined # String
  , name:        undefined # String
  }

  # (Int, Int) => Unit
  show: (left, top) ->
    @set("encodedUrl", null)
    @set("name",       null)
    options = {
      approve: { text: "Load the model", event: "load-model" }
    , deny:    { text: "Cancel" }
    , left:    left
    , top:     top
    }
    @_super(options)
    return

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

      bindModelChooser(modelList, onComplete, pickModel, @get("runtimeMode"))

      return

    # (Event, String) => Unit
    'load-model': (_, eventId) ->
      @fire("ntb-load-nl-url", @get("encodedUrl"), @get("name"))
      return

  }

  partials: {
    dialogContent:
      # coffeelint: disable=max_line_length
      """
      <div class="ntb-dialog-text">
        <span>Pick a NetLogo model from the NetLogo models library to use with your NetTango project.</span>
        <div class="ntb-netlogo-model-chooser">
          <span id="tortoise-model-list" class="model-list tortoise-model-list"></span>
        </div>
      </div>
      """
      # coffeelint: enable=max_line_length
  }
})

export default RactiveModelChooser
