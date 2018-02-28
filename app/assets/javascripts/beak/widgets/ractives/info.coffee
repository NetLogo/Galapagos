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

  mdToHTML: (md) ->
    # html_sanitize is provided by Google Caja - see https://code.google.com/p/google-caja/wiki/JsHtmlSanitizer
    # RG 8/18/15
    window.html_sanitize(
      exports.toHTML(md),
      (url) -> if /^https?:\/\//.test(url) then url else undefined, # URL Sanitizer
      (id) -> id)                                                   # ID Sanitizer

  template:
    """
    <div class='netlogo-tab-content netlogo-info'
         grow-in='{disable:"info-toggle"}' shrink-out='{disable:"info-toggle"}'>
      {{# !isEditing }}
        <div class='netlogo-info-markdown'>{{{mdToHTML(rawText)}}}</div>
      {{ else }}
        <infoeditor rawText='{{rawText}}' />
      {{ / }}
    </div>
    """
})

