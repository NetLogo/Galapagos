loadCodeModal = ->
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

loadCodeModal()
