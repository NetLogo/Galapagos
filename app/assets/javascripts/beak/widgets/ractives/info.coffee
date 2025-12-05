import { markdownToHtml } from "/beak/tortoise-utils.js"

RactiveInfoTabEditor = Ractive.extend({

  data: -> {
    isEditing: false
  }

  # CodeMirror
  infoTabEditor: undefined

  onrender: ->
    @infoTabEditor = CodeMirror(@find('.netlogo-info-editor'), {
      value: @get('rawText'),
      tabsize: 2,
      mode: 'markdown',
      theme: 'netlogo-default',
      editing: @get('isEditing'),
      lineWrapping: true
    })

    @infoTabEditor.on('change', =>
      @set('rawText', @infoTabEditor.getValue())
      @set('info',    @infoTabEditor.getValue())
    )

  # () => Unit
  focus: ->
    @infoTabEditor.focus()
    return

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
      if wasEditing and (not isEditing) and (rawText isnt @get('originalText'))
        @set('originalText', rawText)
        @fire('info-updated', rawText)
      return
  }

  components: {
    infoEditor: RactiveInfoTabEditor
  },

  computed: {
    sanitizedText: ->
      markdownToHtml(@get("rawText"))
  }

  template:
    """
    <div class='netlogo-tab-content netlogo-info'
         grow-in='{disable:"info-toggle"}' shrink-out='{disable:"info-toggle"}'>
      {{# !isEditing }}
        <div class='netlogo-info-markdown'>{{{sanitizedText}}}</div>
      {{ else }}
        <infoEditor rawText='{{rawText}}' />
      {{ / }}
    </div>
    """
})

export default RactiveInfoTabWidget
