window.RactiveEditorWidget = Ractive.extend({
  onrender: ->
    window.editor = CodeMirror(@find('.netlogo-code'), {
      value:   @get('code'),
      tabSize: 2,
      mode:    'netlogo',
      theme:   'netlogo-default',
      readOnly: @get('readOnly'),
      extraKeys: {
        "Ctrl-F": "findPersistent",
        "Cmd-F":  "findPersistent"
      }
    })
    editor.on('change', =>
      newCode = editor.getValue()
      @set('isStale', @get('lastCompiledCode') isnt newCode)
      @set('code',    newCode)
    )

  template:
    """
    <div class="netlogo-tab-content netlogo-code-container"
         intro='grow:{disable:"code-tab-toggle"}' outro='shrink:{disable:"code-tab-toggle"}'>
      {{# !readOnly }}
        <button class="netlogo-widget netlogo-ugly-button netlogo-recompilation-button"
                on-click="recompile" {{# !isStale }}disabled{{/}} >Recompile Code</button>
      {{/}}
      <div class="netlogo-code"></div>
    </div>
    """
})
