InfoTabEditor = Ractive.extend({
  onrender: ->
    window.infoTabEditor = CodeMirror(@find('.netlogo-info-editor'), {
      value: @get('rawText'),
      tabsize: 2,
      mode: 'markdown',
      theme: 'netlogo-default',
      editing: @get('editing'),
      lineWrapping: true
    })

    infoTabEditor.on('change', =>
      @set('rawText', infoTabEditor.getValue())
    )

  template:
    """
    <div class='netlogo-info-editor'></div>
    """
})

window.InfoTabWidget = Ractive.extend({
  components: {
    infoeditor: InfoTabEditor
  },
  template:
    """
    <div class='netlogo-info'>
      <label class='netlogo-toggle-edit-mode'>
        <input type='checkbox' checked='{{editing}}'>
        Edit Mode
      </label>
      {{# !editing }}
        <div class='netlogo-info-markdown'>{{{markdown(rawText)}}}</div>
      {{ else }}
        <infoeditor rawText='{{rawText}}' />
      {{ / }}
    </div>
    """
})

