import newModel from "/new-model.js";
import Tortoise from "/beak/tortoise.js";

# This is a very straightforward translation of the old code to run a NetLogo Web model
# into a Ractive component.  With more work it could encapsulate a lot more
# functionality and also be made more declarative.  -Jeremy b June 2021

RactiveNetLogoModel = Ractive.extend({

  alerter:          null
  modelContainer:   null
  session:          null
  widgetController: null
  workspace:        null

  on: {
    complete: (_) ->
      @modelContainer = @find("#netlogo-model-container")

      window.addEventListener("message", (e) =>
        switch e.data.type
          when "nlw-load-model"
            @loadModel(e.data.nlogo, e.data.path)

          when "nlw-open-new"
            @loadModel(newModel, "NewModel")

          when "nlw-load-url"
            @loadUrl(e.data.url, e.data.name)

          when "nlw-update-model-state"
            @widgetController.setCode(e.data.codeTabContents)

          when "run-baby-behaviorspace"
            reaction = (results) ->
              e.source.postMessage({ type: "baby-behaviorspace-results", id: e.data.id, data: results }, "*")
            @session.asyncRunBabyBehaviorSpace(e.data.config, reaction)

        return
      )
  }

  pageTitle: (modelTitle) ->
    "NetLogo Web #{(modelTitle != null && modelTitle != "") ? ": " + modelTitle : ""}"

  openSession: (session) ->
    @session          = session
    @widgetController = @session.widgetController
    @workspace        = window.workspace
    document.title    = @pageTitle(@session.modelTitle())
    @session.startLoop()
    @alerter.listenForErrors(@widgetController)

  handleCompileResult: (callback) ->
    (result) =>
      if result.type is 'success'
        @openSession(result.session)
        # if this compile came from a new model load, the recompile overlay could still
        # be up from a fail on the previous model.  -Jeremy B June 2021
        @alerter.recompileOverlay.hide()
        if callback?
          callback()

      else
        if result.source is 'compile-recoverable'
          @openSession(result.session)
        @alerter.reportCompilerErrors(result.source, result.errors)

      return

  loadModel: (nlogo, path, rewriters, callback) ->
    if @session?
      @session.teardown()

    Tortoise.fromNlogoSync(nlogo, @modelContainer, path, @handleCompileResult(callback), rewriters)
    Tortoise.finishLoading()

  loadUrl: (url, modelName, rewriters, callback) ->
    if @session?
      @session.teardown()

    Tortoise.fromURL(url, modelName, @modelContainer, @handleCompileResult(callback), rewriters)

  template: """
    <div class="ntb-netlogo-model">
      <div id="netlogo-model-container"></div>
      <div id="netlogo-recompile-overlay"></div>
    </div>
    """

})

export default RactiveNetLogoModel
