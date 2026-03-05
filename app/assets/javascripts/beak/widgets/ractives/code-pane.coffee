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
    code:              ""        # String
    lastCompiledCode:  undefined # String
    lastCompileFailed: undefined # Boolean
    jumpToCode:        undefined # { start: Int, end: Int }
    jumpToProcedure:   undefined # String

    # Internal State
    procedureNames:      {} # Object<String, Number>
    autoCompleteStatus:  false # Boolean
  }

  computed: {
    # Boolean
    isStale: "(code !== lastCompiledCode) || lastCompileFailed"
  }

  observe: {
    code: {
      handler: (code) ->
        @findComponent('codeContainer').setCode(code)
      init: false
    }
    jumpToCode: ->
      @_jumpToCode()
    jumpToProcedure: ->
      @_jumpToProcedure()
  }

  on: {
    complete: ->
      @_setupProceduresDropdown()
      @_setupCtrlS()
      CodeMirror.registerHelper('hint', 'fromList', @_netlogoHintHelper)
      @_setupAutoComplete(@_autoCompleteWords())
      @_jumpToCode()
      @_jumpToProcedure()
      return

    recompile: ->
      @_setupAutoComplete(@_autoCompleteWords())
      @findComponent('codeContainer').focus()
      return

    'code-changed': (_, code) ->
      @set('code', code)
      return
  }

  # () => Unit
  focus: ->
    @findComponent('codeContainer').focus()
    return

  # () => Unit
  refresh: ->
    @findComponent('codeContainer').refresh()
    return

  # () => Unit
  _jumpToCode: ->
    location = @get('jumpToCode')
    if location?
      @set('jumpToCode', null)
      @findComponent('codeContainer').set('jumpToCode', location)
    return

  # () => Unit
  _jumpToProcedure: ->
    procName = @get('jumpToProcedure')
    if procName?
      @set('jumpToProcedure', null)
      procedureNames = CodeUtils.findProcedureNames(@get('code'), 'upper')
      index          = procedureNames[procName.toUpperCase()]
      if index?
        @findComponent('codeContainer').set('jumpToProcedure', { procName, index })
    return

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
                     initialCode={{code}}
                     injectedConfig="{ lineNumbers: true, readOnly: {{isReadOnly}} }"
                     extraClasses="['netlogo-code-tab']" />
    </div>
  """
})

export default RactiveCodePane
