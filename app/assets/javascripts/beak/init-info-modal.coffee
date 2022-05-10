infoModalMonitor = null # MessagePort
ractive = null # Ractive

loadInfoModal = ->

  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-info-modal"
        infoModalMonitor = e.ports[0]
        infoModalMonitor.onmessage = onInfoModalMessage
        return

    console.warn("Unknown info modal postMessage:", e.data)
  )

  template = """
    {{#showInfo}}
      <infotab rawText='{{info}}' isEditing='false' />
    {{/}}
  """

  ractive = new Ractive({
    el:       document.getElementById("info-modal-container")
    template: template,
    components: {
      infotab: RactiveInfoTabWidget
    },
    data: -> {
      info: "",
      showInfo: true
    }
  })

onInfoModalMessage = (e) ->

  switch (e.data.type)
    when "hnw-model-info"
      ractive.set("info", e.data.info)

loadInfoModal()
