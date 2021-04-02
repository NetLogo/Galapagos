ractive = null

window.addEventListener("message", (e) ->
  switch e.data.type

    when "import-code"
      ractive = new Ractive({
        el:       document.body
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

    when "request-save"
      e.source.postMessage({ parcel: ractive.get('code'), identifier: e.data.identifier }, e.origin)

    else
      console.warn("Unknown code pane event type: #{e.data.type}")

)
