import { loadModel } from "./load-model.js"

import { NewSource, ScriptSource } from "/beak/nlogo-source.js"

# ( (MessageEvent) => Unit, (MessageEvent) => Unit, () => Session
# , (Session) => Unit, (MessagePort) => Unit, (MessageEvent) => Unit) =>
# (MessageEvent) => Unit
handleWindowMessage = ( onWidgetMessage, onRainCheckMessage, getSession
                      , setSession, setBabyMonitor, onBabyMonitorMessage) -> (e) ->

  switch e.data.type

    when "hnw-widget-message"
      onWidgetMessage(e)

    when "hnw-cash-raincheck"
      onRainCheckMessage(e)

    when "nlw-load-model"
      loadModel(setSession)(new ScriptSource(e.data.path, e.data.nlogo))

    when "nlw-open-new"
      loadModel(setSession)(new NewSource())

    when "nlw-update-model-state"
      getSession().widgetController.setCode(e.data.codeTabContents)

    when "run-baby-behaviorspace"

      reaction =
        (results) ->
          parcel =
            { type: "baby-behaviorspace-results"
            , id: e.data.id
            , data: results
            }
          e.source.postMessage(parcel, "*")

      getSession().asyncRunBabyBehaviorSpace(e.data.config, reaction)

    when "nlw-request-model-state"
      update = getSession().hnw.getModelState()
      e.source.postMessage({ update, type: "nlw-state-update", sequenceNum: -1 }, "*")

    when "hnw-set-up-baby-monitor"
      babyMonitor           = e.ports[0]
      babyMonitor.onmessage = onBabyMonitorMessage
      setBabyMonitor(babyMonitor)

    when "nlw-resize"

      isValid = (x) -> x?

      height = e.data.height
      width  = e.data.width
      title  = e.data.title

      if [height, width, title].every(isValid)
        frames         = Array.from(document.querySelectorAll(".hnw-join-frame"))
        elem           = frames.find((f) -> f.contentWindow is e.source)
        elem.width     = width
        elem.height    = height
        document.title = title

    when "resize-joiner"
      joiners          = document.querySelectorAll("iframe.hnw-join-frame")
      container        = Array.from(joiners).find((c) -> c.contentWindow is e.source)
      container.height = e.data.data.height
      container.width  = e.data.data.width

    else
      console.warn("Unknown init-host postMessage:", e.data)

  return

export default handleWindowMessage
