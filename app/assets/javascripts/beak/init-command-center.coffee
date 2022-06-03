import "/codemirror-mode.js"

import IDManager            from "./hnw/common/id-manager.js"
import RactiveConsoleWidget from "./widgets/ractives/console.js"

port           = null # MessagePort
compiler       = new BrowserCompiler()
hnwPortToIDMan = new Map()

# (MessagePort) => Number
nextMonIDFor = (mp) ->
  hnwPortToIDMan.get(mp).next("")

# (MessagePort, Object[Any], Array[MessagePort]?) => Unit
postToCommandCenterMonitor = (message, transfers = []) ->

  idObj    = { id: nextMonIDFor(port) }
  finalMsg = Object.assign({}, message, idObj, { source: "nlw-host" })

  port.postMessage(finalMsg, transfers)

  return

# (DOMEvent) -> Unit
onCommandCenterMessage = (e) ->
  switch e.data.type
    when "hnw-command-center-output"
      oldOut = ractive.get("output")
      newOut = e.data.newOutputLine
      ractive.set("output", "#{oldOut}#{newOut}\n")

window.addEventListener("message", (e) ->
  switch e.data.type
    when "hnw-set-up-command-center"
      port           = e.ports[0]
      port.onmessage = onCommandCenterMessage
      compiler.fromNlogo(e.data.nlogo)
      hnwPortToIDMan.set(port, new IDManager())
      document.getElementById("loading-overlay").style.display = "none"
    else
      console.warn("Unknown command center postMessage:", e.data)
)

ractive = new Ractive({
  el:       document.getElementById("netlogo-command-center-container")
  template: '<console output="{{output}}" isEditing="false" checkIsReporter="{{isR}}" />'
  components: {
    console: RactiveConsoleWidget
  }
  data: -> {
    output: "",
    isR: (str) => compiler.isReporter(str)
  }
})

document.querySelector(".netlogo-command-center").style.border = "0"

ractive.on('console.run', (_, target, code, errorLog) ->
  postToCommandCenterMonitor({ type: "nlw-console-run", code })
)
