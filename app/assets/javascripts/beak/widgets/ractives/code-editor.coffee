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
    $('#procedurenames-dropdown').chosen({search_contains: true})
    $('#procedurenames-dropdown').on('change', =>
      procedureNames = @get('procedureNames')
      selectedProcedure = $('#procedurenames-dropdown').val()
      index = procedureNames[selectedProcedure]
      @findComponent('codeEditor').highlightProcedure(selectedProcedure, index)
    )

    $('#procedurenames-dropdown').on('chosen:showing_dropdown', =>
      @setProcedureNames()
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
      <ul class="netlogo-codetab-widget-list">
        <li class="netlogo-codetab-widget-listitem">
          <select class="netlogo-procedurenames-dropdown" id="procedurenames-dropdown" data-placeholder="Jump to Procedure" tabindex="2">
            {{#each procedureNames:name}}
              <option value="{{name}}">{{name}}</option>
            {{/each}}
          </select>
        </li>
        <li class="netlogo-codetab-widget-listitem">
          {{# !isReadOnly }}
            <button class="netlogo-widget netlogo-ugly-button netlogo-recompilation-button{{#isEditing}} interface-unlocked{{/}}"
                on-click="recompile" {{# !isStale }}disabled{{/}} >Recompile Code</button>
          {{/}}
        </li>
      </ul>
      <codeEditor id="netlogo-code-tab-editor" code="{{code}}"
                  injectedConfig="{ lineNumbers: true, readOnly: {{isReadOnly}} }"
                  extraClasses="['netlogo-code-tab']" />
    </div>
    """
  # coffeelint: enable=max_line_length

})
