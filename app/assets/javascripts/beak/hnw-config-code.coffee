ractive = null

nullChoiceText = '<no selection>'

# (String, Array[String], String) => Unit
populateOptions = (elemID, choices, dfault) ->

  elem           = document.getElementById(elemID)
  elem.innerHTML = ""

  choices.concat([nullChoiceText]).forEach(
    (str) ->
      option           = document.createElement("option")
      option.innerText = str
      option.value     = str
      elem.appendChild(option)
      return
  )

  elem.value = dfault

  # Fixing value when item isn't in choice list --Jason B. (6/28/21)
  elem.value =
    if elem.value isnt ''
      elem.value
    else
      nullChoiceText

  return

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

      ractive.on('*.recompile', -> parent.postMessage({ code: ractive.get('code'), type: 'compile-with' }, "*"))

    when "import-procedures"

      { onGo, onSetup, procedures } = e.data

      possibleMetaProcedures =
        procedures.filter(
          ({ argCount, isReporter, isUseableByObserver }) ->
            argCount is 0 and (not isReporter) and isUseableByObserver
        )

      toNames = (arr) -> arr.map((x) -> x.name)

      populateOptions('on-setup-dropdown', toNames(possibleMetaProcedures), onSetup)
      populateOptions('on-go-dropdown'   , toNames(possibleMetaProcedures), onGo   )

    when "request-save"

      orNull =
        (x) ->
          if x isnt nullChoiceText
            x
          else
            null

      parcel =
        { code:    ractive.get('code')
        , onGo:    orNull(document.getElementById('on-go-dropdown'   ).value)
        , onSetup: orNull(document.getElementById('on-setup-dropdown').value)
        }

      e.source.postMessage({ parcel, identifier: e.data.identifier, type: "code-save-response" }, e.origin)

    else
      console.warn("Unknown code pane event type: #{e.data.type}")

)
