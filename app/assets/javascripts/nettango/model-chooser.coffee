import RactiveModalDialog from "./modal-dialog.js"
import { bindModelChooser } from "/models.js"

RactiveModelChooser = RactiveModalDialog.extend({

  data: () -> {
    runtimeMode:      "dev"     # String
  , name:             undefined # String
  , encodedUrl:       undefined # String
  , preRenderContent: true      # Boolean
  , approve:          { text: "Load the model", event: "ntb-load-nl-url", argsMaker: () => @getModelInfo() }
  , deny:             { text: "Cancel" }
  }

  getModelInfo: () ->
    [@get("encodedUrl"), @get("name")]

  # (Int) => Unit
  show: (top) ->
    @set("encodedUrl", null)
    @set("name",       null)
    @_super(top)
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

  }

  partials: {
    headerContent: "Choose a Library Model"
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
