import IDManager            from "./hnw/common/id-manager.js"
import RactiveInfoTabWidget from "./widgets/ractives/info.js"

window.addEventListener("message", (event) ->
  switch event.data.type
    when "hnw-set-up-info-pane"
      event.ports[0].onmessage =
        (e) ->
          switch e.data.type
            when "hnw-model-info"
              ractive.set("info", e.data.info)
      document.getElementById("loading-overlay").style.display = "none"
    else
      console.warn("Unknown info pane postMessage:", event.data)
)

ractive =
  new Ractive({
    el:       document.getElementById("info-pane-container")
    template: "<infoTab rawText='{{info}}' isEditing='false' />",
    components: {
      infoTab: RactiveInfoTabWidget
    },
    data: -> {
      info: "",
    }
  })

document.querySelector(".netlogo-tab-content").style.border = "0"
