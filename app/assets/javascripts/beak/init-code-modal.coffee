# (NEW): TODO
codeModalMonitor = null # MessagePort
ractive = null

loadCodeModal = ->

  # (NEW): TODO
  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-code-modal"
        codeModalMonitor = e.ports[0]
        codeModalMonitor.onmessage = onCodeModalMessage
        return

    console.warn("Unknown code modal postMessage:", e.data)
  )

  # (NEW): TODO
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


# (NEW): TODO
onCodeModalMessage = (e) ->

  switch (e.data.type)
    when "hnw-model-code"
      ractive.findComponent("codePane").setCode(e.data.code)
      ractive.set("lastCompiledCode", e.data.code)

loadCodeModal()
