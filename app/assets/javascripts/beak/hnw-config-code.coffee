ractive = null

window.addEventListener("message", (e) ->
  switch e.data.type

    when "import-code"

      ractive = new Ractive({
        el:       document.getElementById('code-pane')
      , template: "<codePane code='{{code}}' lastCompiledCode='{{lastCompiledCode}}' lastCompileFailed='{{lastCompileFailed}}' isReadOnly='{{isReadOnly}}' />"
      , components: {
          codePane: RactiveModelCodeComponent
        }
      , data: -> {
          code:              e.data.code
        , lastCompiledCode:  e.data.code
        , lastCompileFailed: false
        , isReadOnly:        false
        }
      })

    when "import-procedures"

      { onGo, onSetup, procedures } = e.data

      possibleMetaProcedures =
        procedures.filter(
          ({ argCount, isReporter, isUseableByObserver }) ->
            argCount is 0 and (not isReporter) and isUseableByObserver
        )

      onSetupDD = document.getElementById('on-setup-dropdown')
      onSetupDD.innerHTML = ""

      onGoDD = document.getElementById('on-go-dropdown')
      onGoDD.innerHTML = ""

      possibleMetaProcedures.forEach(

        ({ name }) ->

          option = document.createElement("option")
          option.innerHTML = name
          option.value     = name

          onSetupDD.appendChild(option)
          onSetupDD.value = onSetup

          onGoDD.appendChild(option.cloneNode(true))
          onGoDD.value = onGo

      )

    when "request-save"

      onSetup = document.getElementById('on-setup-dropdown').value
      onGo    = document.getElementById('on-go-dropdown').value

      parcel =
        { code: ractive.get('code')
        , onGo
        , onSetup
        }

      e.source.postMessage({ parcel, identifier: e.data.identifier, type: "code-save-response" }, e.origin)

    else
      console.warn("Unknown code pane event type: #{e.data.type}")

)
