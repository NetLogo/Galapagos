window.RactiveEditorWidget = Ractive.extend({

  data: -> {
    isStale:  false     # Boolean
    readOnly: undefined # Boolean
  }

  components: {
    codeEditor: RactiveCodeContainerMultiline
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
                  injectedConfig="{ readOnly: {{readOnly}} }" extraClasses="['netlogo-code-tab']" />
    </div>
    """

})
