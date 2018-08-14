window.RactiveModelCodeComponent = Ractive.extend({

  data: -> {
    code:              undefined # String
  , isReadOnly:        undefined # Boolean
  , lastCompiledCode:  undefined # String
  , lastCompileFailed:     false # Boolean
  , procedureNames:           {} # Object[String, Number]
  , autoCompleteStatus:    false # Boolean
  , codeUsage:                [] # Array[{pos: CodeMirror.Pos, lineNumber: Number, line: String }]
  , usageVisibility:       false # Boolean
  , selectedCode:      undefined # String
  , usageLeft:         undefined # String
  , usageTop:          undefined # String
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

  setupAutoComplete: (hintList) ->
    CodeMirror.registerHelper('hintWords', 'netlogo', hintList)
    editor = @findComponent('codeEditor').getEditor()
    editor.on('keyup', (cm, event) =>
      if not cm.state.completionActive and event.keyCode > 64 and event.keyCode < 91 and @get('autoCompleteStatus')
        cm.showHint({completeSingle: false})
    )
    return

  netLogoHintHelper: (cm, options) ->
    cur = cm.getCursor()
    token = cm.getTokenAt(cur)
    to = CodeMirror.Pos(cur.line, token.end)
    if token.string and /\S/.test(token.string[token.string.length - 1])
      term = token.string
      from = CodeMirror.Pos(cur.line, token.start)
    else
      term = ''
      from = to
    found = options.words.filter( (word) -> word.slice(0, term.length) is term )
    if found.length > 0
      return { list: found, from: from, to: to }

  autoCompleteWords: ->
    allKeywords       = new Set(window.keywords.all)
    supportedKeywords = Array.from(allKeywords)
      .filter( (kw) -> (not window.keywords.unsupported.includes(kw)) )
      .map(    (kw) -> kw.replace("\\", "") )
    Object.keys(@getProcedureNames()).concat(supportedKeywords)

  setupCodeUsagePopup: ->
    editor = @findComponent('codeEditor').getEditor()
    codeUsageMap = {
      'Ctrl-U': =>
        if editor.somethingSelected()
          @setCodeUsage()
      ,'Cmd-U': =>
        if editor.somethingSelected()
          @setCodeUsage()
    }
    editor.addKeyMap(codeUsageMap)

    editor.on('cursorActivity', (cm) =>
      if @get('usageVisibility')
        @set('usageVisibility', false)
    )

    return

  getCodeUsage: ->
    editor = @findComponent('codeEditor').getEditor()
    selectedCode = editor.getSelection().trim()
    @set('selectedCode', selectedCode)
    codeString = @get('code')
    check = ///\b(#{selectedCode})\b///g
    codeUsage = []
    while (match = check.exec(codeString))
      pos        = editor.posFromIndex(match.index + match[1].length)
      lineNumber = pos.line + 1
      line       = editor.getLine(pos.line)
      codeUsage.push( { pos, lineNumber, line } )
    codeUsage

  setCodeUsage: ->
    codeUsage = @getCodeUsage()
    editor = @findComponent('codeEditor').getEditor()
    @set('codeUsage', codeUsage)
    pos = editor.cursorCoords(editor.getCursor())
    @set('usageLeft', pos.left)
    @set('usageTop', pos.top)
    @set('usageVisibility', true)
    return

  on: {
    'complete': (_) ->
      @setupProceduresDropdown()
      CodeMirror.registerHelper('hint', 'fromList', @netLogoHintHelper)
      @setupAutoComplete(@autoCompleteWords())
      @setupCodeUsagePopup()
      return

    'recompile': (_) ->
      @setupAutoComplete(@autoCompleteWords())
      return

    'jump-to-usage': (context, usagePos) ->
      editor = @findComponent('codeEditor').getEditor()
      selectedCode = @get('selectedCode')
      end = usagePos
      start = CodeMirror.Pos(end.line, end.ch - selectedCode.length)
      editor.setSelection(start, end)
      @set('usageVisibility', false)
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
        <li class="netlogo-codetab-widget-listitem">
          <input type='checkbox' class="netlogo-autocomplete-checkbox" checked='{{autoCompleteStatus}}'>
          <label class="netlogo-autocomplete-label">
            Auto Complete {{# autoCompleteStatus}}Enabled{{else}}Disabled{{/}}
          </label>
        </li>
      </ul>
      <codeEditor id="netlogo-code-tab-editor" code="{{code}}"
                  injectedConfig="{ lineNumbers: true, readOnly: {{isReadOnly}} }"
                  extraClasses="['netlogo-code-tab']" />
    </div>
    <div class="netlogo-codeusage-popup" style="left: {{usageLeft}}px; top: {{usageTop}}px;">
      {{# usageVisibility}}
        <ul class="netlogo-codeusage-list">
          {{#each codeUsage}}
            <li class="netlogo-codeusage-item" on-click="[ 'jump-to-usage', this.pos ]">{{this.lineNumber}}: {{this.line}}</li>
          {{/each}}
        </ul>
      {{/}}
    </div>
    """
  # coffeelint: enable=max_line_length

})
