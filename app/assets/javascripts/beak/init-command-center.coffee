commandCenterMonitor = null # MessagePort

loadCodeModal = ->

  # (NEW): Handle messages to command center window (iframe)
  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-command-center"
        commandCenterMonitor = e.ports[0]
        commandCenterMonitor.onmessage = onCommandCenterMessage
        return

    console.warn("Unknown command center postMessage:", e.data)
  )

  compiler = new BrowserCompiler()
  checkIsReporter = (str) => compiler.isReporter(str)

  # (NEW): Command center setup
  template = """
    <console output="{{consoleOutput}}" isEditing="false" checkIsReporter="{{checkIsReporter}}" />
  """

  new Ractive({
    el:       document.getElementById("command-center-container")
    template: template,
    components: {
      console: RactiveConsoleWidget
    },
    data: -> {
      checkIsReporter: checkIsReporter,
      consoleOutput: ""
    }
  })

# TODO
onCommandCenterMessage = (e) ->
  return

loadCodeModal()
