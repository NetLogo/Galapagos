codeModalMonitor = null # MessagePort
ractive = null # Ractive
compiler = new BrowserCompiler()
codeTab = ""
widgets = []
hnwPortToIDMan = new Map()
alertWindow = null # HTMLElement
isStandalone = false

nlogoScript = document.querySelector("#nlogo-code")
isStandaloneHTML = nlogoScript.textContent.length > 0
window.nlwAlerter = new NLWAlerter(document.getElementById("alert-overlay"), isStandaloneHTML)

# String -> Boolean -> String -> Unit
display = (title, dismissable, content) ->
  alertWindow.querySelector("#alert-title").innerHTML = title
  alertWindow.querySelector("#alert-message").innerHTML = content

  if isStandalone
    alertWindow.querySelector(".standalone-text").style.display = ''

  if not dismissable
    alertWindow.querySelector("#alert-dismiss-container").style.display = 'none'
  else
    alertWindow.querySelector("#alert-dismiss-container").style.display = ''

  alertWindow.style.display = ''

  return

# String -> Boolean -> String -> Unit
displayError = (content, dismissable = true, title = "Error") ->
  display(title, dismissable, content)
  return

loadCodeModal = ->

  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-code-modal"
        codeModalMonitor = e.ports[0]
        codeModalMonitor.onmessage = onCodeModalMessage
        result = compiler.fromNlogo(e.data.nlogo)

        codeTab = result.code
        widgets = JSON.parse(result.widgets)
        hnwPortToIDMan.set(codeModalMonitor, new window.IDManager())

        alertWindow = document.getElementById("alert-overlay")

        return

    console.warn("Unknown code modal postMessage:", e.data)
  )

  template = """
    <label class="netlogo-tab netlogo-active">
      <input id="code-tab-toggle" type="checkbox" checked="true" />
      <span class="netlogo-tab-text">NetLogo Code</span>
    </label>
    <codePane code='' lastCompiledCode='{{lastCompiledCode}}' lastCompileFailed='false' isReadOnly='false' />
  """

  ractive = new Ractive({
    el:       document.getElementById("code-modal-container")
    template: template,
    components: {
      codePane: RactiveModelCodeComponent
    },
    data: -> {
      lastCompiledCode: ""
    }
  })

  ractive.on('*.recompile'     , (_, callback) =>
    postToCodeModalMonitor({ type: "nlw-recompile", code: ractive.findComponent("codePane").get("code") })
  )

# (MessagePort) => Number
nextMonIDFor = (port) ->
  hnwPortToIDMan.get(port).next("")

# (MessagePort, Object[Any], Array[MessagePort]?) => Unit
postToCodeModalMonitor = (message, transfers = []) ->

  idObj    = { id: nextMonIDFor(codeModalMonitor) }
  finalMsg = Object.assign({}, message, idObj, { source: "nlw-host" })

  codeModalMonitor.postMessage(finalMsg, transfers)

# TODO
onCodeModalMessage = (e) ->

  switch (e.data.type)
    when "hnw-model-code"
      ractive.findComponent("codePane").setCode(e.data.code)
      ractive.set("lastCompiledCode", e.data.code)

    when "hnw-code-modal-errors"
      displayError(e.data.messages)

loadCodeModal()
