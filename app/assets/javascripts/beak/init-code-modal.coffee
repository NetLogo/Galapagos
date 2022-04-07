# (NEW): TODO
codeModalMonitor = null # MessagePort

loadCodeModal = ->
  # (NEW): TODO
  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-code-modal"
        codeModalMonitor = e.ports[0]
        codeModalMonitor.onmessage = onCodeModalMessage
        console.log("codeModalMonitor:", codeModalMonitor)
        return

    console.warn("Unknown command center postMessage:", e.data)
  )

  # (NEW): TODO
  checkIsReporter = (str) => compiler.isReporter(str)

  template = """
    <label class="netlogo-tab netlogo-active">
        <input id="code-tab-toggle" type="checkbox" checked="true" />
        <span class="netlogo-tab-text">NetLogo Code</span>
      </label>
      <codePane code='{{code}}' lastCompiledCode='{{code}}' lastCompileFailed='false' isReadOnly='false' />
  """

  new Ractive({
    el:       document.getElementById("command-center-container")
    template: template,
    components: {
      console: RactiveConsoleWidget
    },
    data: -> {
      consoleOutput: ""
    }
  })

# (NEW): TODO
onCodeModalMessage = (e) ->

  switch (e.data.type)
    when "hnw-model-code"
      console.log("CODE!!!!")
      console.log(e.data.code)

loadCodeModal()
