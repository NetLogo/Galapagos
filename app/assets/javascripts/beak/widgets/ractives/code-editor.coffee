window.RactiveModelCodeComponent = Ractive.extend({

  data: -> {
    code:              undefined # String
  , isReadOnly:        undefined # Boolean
  , lastCompiledCode:  undefined # String
  , lastCompileFailed:     false # Boolean
  }

  components: {
    codeEditor: RactiveCodeContainerMultiline
  }

  computed: {
    isStale: '(${code} !== ${lastCompiledCode}) || ${lastCompileFailed}'
  }

  # (String) => Unit
  setCode: (code) ->
    @findComponent('codeEditor').setCode(code)
    return

  # coffeelint: disable=max_line_length
  template:
    """
    <div class="netlogo-tab-content netlogo-code-container"
         grow-in='{disable:"code-tab-toggle"}' shrink-out='{disable:"code-tab-toggle"}'>
      {{# !isReadOnly }}
        <button class="netlogo-widget netlogo-ugly-button netlogo-recompilation-button{{#isEditing}} interface-unlocked{{/}}"
                on-click="recompile" {{# !isStale }}disabled{{/}} >Recompile Code</button>
      {{/}}
      <codeEditor id="netlogo-code-tab-editor" code="{{code}}"
                  injectedConfig="{ lineNumbers: true, readOnly: {{isReadOnly}} }"
                  extraClasses="['netlogo-code-tab']" />
    </div>
    """
  # coffeelint: enable=max_line_length

})
