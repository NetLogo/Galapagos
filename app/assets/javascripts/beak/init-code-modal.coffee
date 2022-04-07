loadCodeModal = ->
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

loadCodeModal()
