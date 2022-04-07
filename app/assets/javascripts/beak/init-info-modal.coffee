# (NEW): TODO
infoModalMonitor = null # MessagePort
ractive = null

loadInfoModal = ->

  # (NEW): TODO
  window.addEventListener("message", (e) ->

    switch (e.data.type)
      when "hnw-set-up-info-modal"
        infoModalMonitor = e.ports[0]
        infoModalMonitor.onmessage = onInfoModalMessage
        return

    console.warn("Unknown info modal postMessage:", e.data)
  )

  template = """
    <label class="netlogo-tab netlogo-active">
        <input id="info-toggle" type="checkbox" checked="true" />
        <span class="netlogo-tab-text">Model Info</span>
      </label>
    <infotab rawText='{{info}}' isEditing='false' />
  """

  ractive = new Ractive({
    el:       document.getElementById("info-modal-container")
    template: template,
    components: {
      infotab: RactiveInfoTabWidget
    },
    data: -> {
      info: ""
    }
  })

# (NEW): TODO
onInfoModalMessage = (e) ->

  switch (e.data.type)
    when "hnw-model-info"
      ractive.set("info", e.data.info)

loadInfoModal()
