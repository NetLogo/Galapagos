import newModelNetTango from "./new-model-nettango.js"
import Tortoise from "/beak/tortoise.js"
import { createNotifier, listenerEvents } from "../notifications/listener-events.js"
import { createModelOracle } from "../queries/model-oracle.js"
import { fakeStorage } from "../namespace-storage.js"

# This is a very straightforward translation of the old code to run a NetLogo Web model
# into a Ractive component.  With more work it could encapsulate a lot more
# functionality and also be made more declarative.  -Jeremy B June 2021

RactiveNetLogoModel = Ractive.extend({

  rewriters:        null # Array[Rewriter]
  listeners:        null # Array[Listener]
  alerter:          null # AlertDisplay
  modelContainer:   null # Element
  session:          null # SessionLite
  widgetController: null # WidgetController
  workspace:        null # Workspace

  on: {
    complete: (_) ->
      @modelContainer = @find("#netlogo-model-container")
      @notifyListeners = createNotifier(listenerEvents, @listeners)

      window.addEventListener("message", (e) =>
        switch e.data.type
          when "nlw-load-model"
            @notifyListeners('model-load', 'file', e.data.path)
            @loadModel(e.data.nlogo, 'disk', e.data.path)

          when "nlw-open-new"
            @notifyListeners('model-load', 'new-model')
            @loadModel(newModelNetTango, 'new', 'NewModel')

          when "nlw-load-url"
            @notifyListeners('model-load', 'url', e.data.url)
            @loadUrl(e.data.url)

          when "nlw-update-model-state"
            @widgetController.setCode(e.data.codeTabContents)

          when "run-baby-behaviorspace"
            reaction = (results) ->
              e.source.postMessage({ type: "baby-behaviorspace-results", id: e.data.id, data: results }, "*")
            @session.asyncRunBabyBehaviorSpace(e.data.config, reaction)

          when "nlw-request-model-state"
            update = session.hnw.getModelState()
            e.source.postMessage({ update, type: "nlw-state-update" }, "*")

          when "nlw-request-view"
            base64 = session.widgetController.viewController.view.visibleCanvas.toDataURL("image/png")
            e.source.postMessage({ base64, type: "nlw-view" }, "*")

          when "nlw-subscribe-to-updates"
            @session.hnw.subscribe(e.source, "NetTango")

          when "nlw-apply-update"

            { plotUpdates, ticks, viewUpdate } = e.data.update

            world.ticker.reset()
            world.ticker.importTicks(ticks)

            vc = @session.widgetController.viewController
            vc.applyUpdate(viewUpdate)
            vc.repaint()

        return
      )
  }

  pageTitle: (modelTitle) ->
    title = if modelTitle? and modelTitle.trim() isnt "" then ": #{modelTitle}" else ""
    "NetLogo Web#{title}"

  openSession: (session) ->
    @session          = session
    @widgetController = @session.widgetController
    @oracle           = createModelOracle(@session, globalThis.workspace)
    document.title    = @pageTitle(@oracle.getModelTitle())
    @session.startLoop()
    @alerter.setWidgetController(@widgetController)

  makeCompileResultHandler: (callback) ->
    (result) =>
      if result.type is 'success'
        @openSession(result.session)
        if callback?
          callback()

      else
        if result.source is 'compile-recoverable'
          @openSession(result.session)
        @notifyListeners('compiler-error', result.source, result.errors)

      return

  loadModel: (nlogo, sourceType, path, callback) ->
    if @session?
      @session.teardown()

    nlogoSource = Tortoise.createSource(sourceType, path, nlogo)
    Tortoise.fromNlogoSync(
      nlogoSource
    , @modelContainer
    , @get('locale')
    , false
    , null
    , @makeCompileResultHandler(callback)
    , @rewriters
    , @listeners
    )
    Tortoise.finishLoading()

  loadUrl: (url, callback) ->
    if @session?
      @session.teardown()

    Tortoise.fromURL(
      url
    , @modelContainer
    , @get('locale')
    , ((s) -> s.nlogo)
    , @makeCompileResultHandler(callback)
    , @rewriters
    , @listeners
    )

  template: """
    <div class="ntb-netlogo-model">
      <div id="netlogo-model-container"></div>
    </div>
    """

})

export default RactiveNetLogoModel
