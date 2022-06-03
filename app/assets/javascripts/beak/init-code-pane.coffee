import "/codemirror-mode.js"

import AlertDisplay from "/alert-display.js"

import IDManager                 from "./hnw/common/id-manager.js"
import RactiveModelCodeComponent from "./widgets/ractives/code-editor.js"

port           = null # MessagePort
ractive        = null # Ractive
compiler       = new BrowserCompiler()
hnwPortToIDMan = new Map()

alerter = new AlertDisplay(document.getElementById("alert-container"), false)

# (DOMEvent) => Unit
onCodePaneMessage = (e) ->

  switch e.data.type

    when "hnw-model-code", "hnw-recompile-success"
      code = e.data.code
      ractive.findComponent("codePane").setCode(code)
      ractive.set("code", code)
      ractive.set("lastCompiledCode", code)
      ractive.set("lastCompileFailed", false)

    when "hnw-recompile-failure"
      alerter._ractive.fire("show", title, content, [])
      ractive.set("lastCompileFailed", true)

# (MessagePort) => Number
nextMonIDFor = (mp) ->
  hnwPortToIDMan.get(mp).next("")

# (MessagePort, Object[Any], Array[MessagePort]?) => Unit
postToCodePaneMonitor = (message, transfers = []) ->

  idObj    = { id: nextMonIDFor(port) }
  finalMsg = Object.assign({}, message, idObj, { source: "nlw-host" })

  port.postMessage(finalMsg, transfers)

  return

window.addEventListener("message", (e) ->
  switch e.data.type
    when "hnw-set-up-code-pane"
      port           = e.ports[0]
      port.onmessage = onCodePaneMessage
      compiler.fromNlogo(e.data.nlogo)
      hnwPortToIDMan.set(port, new IDManager())
      document.getElementById("loading-overlay").style.display = "none"
    else
      console.warn("Unknown code pane postMessage:", e.data)
)

template = """
  {{#showCode}}
    {{#lastCompileFailed}}
      <div class="netlogo-code-compile-error">FAILED COMPILATION</div>
    {{/}}
    <codePane code='{{code}}' lastCompiledCode='{{lastCompiledCode}}'
              lastCompileFailed='{{lastCompileFailed}}' isReadOnly='false' />
  {{/}}
"""

ractive = new Ractive({
  el:       document.getElementById("code-pane-container")
  template: template,
  components: {
    codePane: RactiveModelCodeComponent
  },
  data: -> {
    code: "",
    lastCompiledCode: "",
    lastCompileFailed: false,
    showCode: true
  }
})

ractive.on('*.recompile', (_, callback) =>
  code = ractive.findComponent("codePane").get("code")
  postToCodePaneMonitor({ type: "nlw-recompile", code })
)
