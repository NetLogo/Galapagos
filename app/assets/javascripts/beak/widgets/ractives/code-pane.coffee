import keywords from "/keywords.js"
import CodeUtils from "/beak/widgets/code-utils.js"
import { RactiveCodeContainerMultiline } from "./subcomponent/code-container.js"

RactiveCodePane = Ractive.extend({
  components: {
    codeContainer: RactiveCodeContainerMultiline
  }

  data: -> {
    # Props
    isReadOnly:        undefined # Boolean
    initialCode:       ""        # String
    lastCompiledCode:  undefined # String
    lastCompileFailed: undefined # Boolean

    # Internal State
    procedureNames:      {} # Object<String, Number>
    autoCompleteStatus:  false # Boolean
  }

  computed: {
    # String
    code: {
      get: -> @findComponent('codeContainer').get('code')
      set: (code) -> @findComponent('codeContainer').setCode(code)
    }
    # Boolean
    isStale: "(code !== lastCompiledCode) || lastCompileFailed"
  }

  on: {
    complete: ->
      @_setupProceduresDropdown()
      @_setupCtrlS()
      CodeMirror.registerHelper('hint', 'fromList', @_netlogoHintHelper)
      @_setupAutoComplete(@_autoCompleteWords())
      return

    recompile: ->
      @_setupAutoComplete(@_autoCompleteWords())
      @findComponent('codeContainer').focus()
      return
  }

  _setupCtrlS: ->
    editor = @findComponent('codeContainer').getEditor()
    if editor?
      editor.addKeyMap({
        'Ctrl-S': =>
          if @get('isStale')
            @fire('recompile', 'user')
          @findComponent('codeContainer').focus()
      })
    return

  _setupProceduresDropdown: ->
    dropdownElement = $(@find('.netlogo-procedurenames-dropdown'))
    dropdownElement.chosen({
      search_contains: true,
      width: getComputedStyle(dropdownElement[0]).getPropertyValue('width')
      # The width needs to be manually specified to match, otherwise chosen menu shows 0 width.
    })
    dropdownElement.on('change', =>
      procedureNames   = @get('procedureNames')
      selectedProcedure = dropdownElement.val()
      index            = procedureNames[selectedProcedure]
      @findComponent('codeContainer').highlightProcedure(selectedProcedure, index)
    )
    dropdownElement.on('chosen:showing_dropdown', =>
      procedureNames = CodeUtils.findProcedureNames(@get('code'), 'as-written')
      @set('procedureNames', procedureNames)
      dropdownElement.trigger('chosen:updated')
    )
    return

  _netlogoHintHelper: (cm, options) ->
    cur   = cm.getCursor()
    token = cm.getTokenAt(cur)
    to    = CodeMirror.Pos(cur.line, token.end)
    if token.string and /\S/.test(token.string[token.string.length - 1])
      term = token.string
      from = CodeMirror.Pos(cur.line, token.start)
    else
      term = ''
      from = to
    found = options.words.filter((word) -> word.slice(0, term.length) is term)
    if found.length > 0
      return { list: found, from: from, to: to }

  _autoCompleteWords: ->
    allKeywords       = new Set(keywords.all)
    supportedKeywords = Array.from(allKeywords)
      .filter((kw) -> not keywords.unsupported.includes(kw))
      .map(   (kw) -> kw.replace("\\", ""))
    Object.keys(CodeUtils.findProcedureNames(@get('code'), 'lower')).concat(supportedKeywords)

  _setupAutoComplete: (hintList) ->
    CodeMirror.registerHelper('hintWords', 'netlogo', hintList)
    editor = @findComponent('codeContainer').getEditor()
    if editor?
      editor.on('keyup', (cm, event) =>
        if not cm.state.completionActive and event.keyCode > 64 and event.keyCode < 91 and @get('autoCompleteStatus')
          cm.showHint({completeSingle: false})
      )
    return

  template: """
    <div id="netlogo-code-tab" class="netlogo-tab-content netlogo-code-container">
      <ul class="netlogo-codetab-widget-list">
        <li class="netlogo-codetab-widget-listitem">
          <select class="netlogo-procedurenames-dropdown" data-placeholder="Jump to Procedure" tabindex="2">
            {{#each procedureNames:name}}
              <option value="{{name}}">{{name}}</option>
            {{/each}}
          </select>
        </li>
        <li class="netlogo-codetab-widget-listitem">
          {{# !isReadOnly }}
            <button
              class="netlogo-widget netlogo-ugly-button netlogo-recompilation-button"
              {{# !isStale}}disabled{{/}}
              on-click="['recompile', 'user']"
            >Recompile Code</button>
          {{/}}
        </li>
        <li class="netlogo-codetab-widget-listitem">
          <input type='checkbox' class="netlogo-autocomplete-checkbox" checked='{{autoCompleteStatus}}'>
          <label class="netlogo-autocomplete-label">
            Auto Complete {{# autoCompleteStatus}}Enabled{{else}}Disabled{{/}}
          </label>
        </li>
      </ul>
      <codeContainer id="netlogo-code-tab-editor"
                     initialCode={{initialCode}}
                     injectedConfig="{ lineNumbers: true, readOnly: {{isReadOnly}} }"
                     extraClasses="['netlogo-code-tab']" />
    </div>
  """
})

export default RactiveCodePane
