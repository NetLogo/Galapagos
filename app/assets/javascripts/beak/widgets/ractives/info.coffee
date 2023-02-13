RactiveInfoTabEditor = Ractive.extend({

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

RactiveInfoTabWidget = Ractive.extend({

  data: () -> {
    isEditing:    false     # Boolean
    rawText:      undefined # String
    info:         undefined # String
    originalText: undefined # String
  }

  onrender: ->
    @set('originalText', @get('rawText'))
    return

  observe: {
    isEditing: (isEditing, wasEditing) ->
      rawText = @get('rawText')
      if wasEditing and !isEditing and (rawText isnt @get('originalText'))
        @set('originalText', rawText)
        @fire('info-updated', rawText)
      return
  }

  components: {
    infoeditor: RactiveInfoTabEditor
  },

  computed: {
    sanitizedText: ->
      @mdToHTML(@get("rawText"))
  }

  mdToHTML: (md) ->
    # html_sanitize is provided by Google Caja - see https://code.google.com/p/google-caja/wiki/JsHtmlSanitizer
    # RG 8/18/15
    window.html_sanitize(
      window.markdown.toHTML(md),
      (url) -> if /^https?:\/\//.test(url) then url else undefined, # URL Sanitizer
      (id) -> id)                                                   # ID Sanitizer

  template:
    """
    <div class='netlogo-tab-content netlogo-info'
         grow-in='{disable:"info-toggle"}' shrink-out='{disable:"info-toggle"}'>
      {{# !isEditing }}
        <div class='netlogo-info-markdown'>{{{sanitizedText}}}</div>
      {{ else }}
        <infoeditor rawText='{{rawText}}' />
      {{ / }}
    </div>
    """
})

export default RactiveInfoTabWidget
