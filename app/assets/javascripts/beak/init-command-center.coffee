# (NEW): TODO
commandCenterMonitor = null # MessagePort

# (NEW): TODO
loadCodeModal = ->

  # (NEW): TODO
  compiler = new BrowserCompiler()
  checkIsReporter = (str) => compiler.isReporter(str)

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
      consoleOutput: ""
    }
  })

  # (NEW): TODO
  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-command-center"
        commandCenterMonitor = e.ports[0]
        commandCenterMonitor.onmessage = onCommandCenterMessage
        console.log("commandCenterMonitor:", commandCenterMonitor)
        return

    console.warn("Unknown command center postMessage:", e.data)
  )

onCommandCenterMessage = (e) ->
  return


loadCodeModal()
