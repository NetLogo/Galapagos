window.RactiveModelCodeComponent = Ractive.extend({

  data: -> {
    code:              undefined # String
  , isReadOnly:        undefined # Boolean
  , lastCompiledCode:  undefined # String
  , lastCompileFailed:     false # Boolean
  , procedureNames:           {}
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

  setupProceduresDropdown: ->
    editor = @
    $('#procedurenames-dropdown').chosen({search_contains: true}).change(
      (event) ->
        procedureNames = editor.get('procedureNames')
        selectedProcedure = $('#procedurenames-dropdown').val()
        index = procedureNames[selectedProcedure]
        editor.findComponent('codeEditor').highlightProcedure(selectedProcedure, index)
    )

    $('#procedurenames-dropdown').on('chosen:showing_dropdown', ->
      editor.setProcedureNames()
    )
    return
 
  getProcedureNames: ->
    codeString = @get('code')
    procedureNames = {}
    procedureCheck = /^\s*(?:to|to-report)\s(?:\s*;.*\n)*\s*(\w\S*)/gm
    while (procedureMatch = procedureCheck.exec(codeString))
      procedureNames[procedureMatch[1]] = procedureMatch.index + procedureMatch[0].length
    procedureNames
    
  setProcedureNames: ->
    procedureNames = @getProcedureNames()
    @set('procedureNames', procedureNames)
    $('#procedurenames-dropdown').trigger('chosen:updated')
    return

  on: {
    'complete': (_) ->
      @setupProceduresDropdown()
      return
  }

  # coffeelint: disable=max_line_length
  template:
    """
    <div class="netlogo-tab-content netlogo-code-container"
         grow-in='{disable:"code-tab-toggle"}' shrink-out='{disable:"code-tab-toggle"}'>
      <select class="netlogo-procedurenames-dropdown" id="procedurenames-dropdown">
        <option hidden disabled selected>Jump to Procedure</option>
        {{#each procedureNames:name}}
          <option value="{{name}}">{{name}}</option>
        {{/each}}
      </select>
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
