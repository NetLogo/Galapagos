window.RactiveInfoTabEditor = Ractive.extend({

  data: -> {
    isEditing: false
  }

  onrender: ->
    infoTabEditor = CodeMirror(@find('.netlogo-info-editor'), {
      value: @get('rawText'),
      tabsize: 2,
      mode: 'markdown',
      theme: 'netlogo-default',
      editing: @get('isEditing'),
      lineWrapping: true
    })

    infoTabEditor.on('change', =>
      @set('rawText', infoTabEditor.getValue())
      @set('info',    infoTabEditor.getValue())
    )

  template:
    """
    <div class='netlogo-info-editor'></div>
    """
})

window.RactiveInfoTabWidget = Ractive.extend({
  components: {
    infoeditor: RactiveInfoTabEditor
  },
  toMarkdown: (x) ->
    window.markdown.toHTML(x)
  template:
    """
    <div class='netlogo-tab-content netlogo-info'
         grow-in='{disable:"info-toggle"}' shrink-out='{disable:"info-toggle"}'>
      {{# !isEditing }}
        <div class='netlogo-info-markdown'>{{{toMarkdown(rawText)}}}</div>
      {{ else }}
        <infoeditor rawText='{{rawText}}' />
      {{ / }}
    </div>
    """
})

