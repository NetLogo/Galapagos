window.RactiveEditorWidget = Ractive.extend({

  data: -> {
    code:             undefined # String
  , lastCompiledCode: undefined # String
  , readOnly:         undefined # Boolean
  }

  components: {
    codeEditor: RactiveCodeContainerMultiline
  }

  computed: {
    isStale: '${code} !== ${lastCompiledCode}'
  }

  template:
    """
    <div class="netlogo-tab-content netlogo-code-container"
         intro='grow:{disable:"code-tab-toggle"}' outro='shrink:{disable:"code-tab-toggle"}'>
      {{# !readOnly }}
        <button class="netlogo-widget netlogo-ugly-button netlogo-recompilation-button"
                on-click="recompile" {{# !isStale }}disabled{{/}} >Recompile Code</button>
      {{/}}
      <codeEditor id="netlogo-code-tab-editor" code="{{code}}"
                  injectedConfig="{ lineNumbers: true, readOnly: {{readOnly}} }"
                  extraClasses="['netlogo-code-tab']" />
    </div>
    """

})
