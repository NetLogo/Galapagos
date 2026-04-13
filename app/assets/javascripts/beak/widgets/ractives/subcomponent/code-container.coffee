RactiveCodeContainerBase = Ractive.extend({

  _editor: undefined # CodeMirror

  data: -> {
    code:           undefined # String
  , extraClasses:   undefined # Array[String]
  , extraConfig:    undefined # Object
  , localConfig:    undefined # Object
  , id:             undefined # String
  , initialCode:    undefined # String
  , isDisabled:     false
  , injectedConfig: undefined # Object
  , onchange:       (->)      # (String) => Unit
  , style:          undefined # String

  , tabindex:       undefined # String
  , 'aria-label':   undefined # String
  }

  # An astute observer will ask what the purpose of `initialCode` is--why wouldn't we just make it
  # equivalent to `code`?  It's a good (albeit maddening) question.  Ractive does some funny stuff
  # if the code that comes in is the same as what is getting hit by `set` in the editor's on-change
  # event.  Basically, even though we explicitly say all over the place that we don't want to be
  # doing two-way binding, that `set` call will change the value here and everywhere up the chain.
  # So, to avoid that, `initialCode` is a dummy variable, and we dump it into `code` as soon as
  # reasonably possible.  --Jason B. (5/2/16)
  oncomplete: ->
    initialCode = @get('initialCode')
    @set('code', initialCode ? @get('code') ? "")
    @_setupCodeMirror()
    return

  twoway: false

  _setupCodeMirror: ->

    id        = @get('id')
    editorDiv = if id? then @find("##{id}") else @find('.netlogo-code')
    baseConfig = {
      mode: 'netlogo'
    , theme: 'netlogo-default'
    , value: @get('code').toString()
    }
    config     = Object.assign(
      {}, baseConfig,
      @get('extraConfig') ? {},
      @get('injectedConfig') ? {},
      @get('localConfig') ? {}
    )
    @_editor   = new CodeMirror(editorDiv, config)

    @_editor.on('change', =>
      code = @_editor.getValue()
      @set('code', code)
      @parent.fire('code-changed', code)
      @get('onchange')(code)
    )

    @_editor.on('blur', =>
      @fire('change')
    )

    @observe('isDisabled', (isDisabled) ->
      @_editor.setOption('readOnly', if isDisabled then 'nocursor' else false)
      classes = this.find('.netlogo-code').querySelector('.CodeMirror-scroll').classList
      if isDisabled
        classes.add('cm-disabled')
      else
        classes.remove('cm-disabled')
      return
    )

    return

  # () => Unit
  refresh: ->
    @_editor.refresh()
    return

  # (String) => Unit
  setCode: (code) ->
    str = code.toString()
    if @_editor? and @_editor.getValue() isnt str
      @_editor.setValue(str)
    return

  # () => Unit
  focus: ->
    @_editor.focus()
    return

  # () => CodeMirror
  getEditor: ->
    @_editor

  template:
    """
    <div
      id="{{id}}"
      class="netlogo-code {{(extraClasses || []).join(' ')}}"
      style="{{style}}"
      translate="no"
      aria-label="{{aria-label}}"
    />
    """

})

RactiveCodeContainerMultiline = RactiveCodeContainerBase.extend({

  data: -> {
    extraConfig: {
      tabSize: 2
      extraKeys: {
        "Ctrl-F": "findPersistent"
        "Cmd-F":  "findPersistent"
      }
    }
    , jumpToProcedure: undefined # { procName: String, index: Int }
    , jumpToCode:      undefined # { start: Int, end: Int }
  }

  oncomplete: ->
    @_super()
    @jumpToProcedure()
    @jumpToCode()

  observe: {
    'jumpToProcedure': ->
      @jumpToProcedure()

    'jumpToCode': ->
      @jumpToCode()
  }

  # (String, Int) => Unit
  highlightProcedure: (procedureName, index) ->
    end   = @_editor.posFromIndex(index)
    start = CodeMirror.Pos(end.line, end.ch - procedureName.length)
    @_editor.setSelection(start, end)
    return

  # ({ start: Int, end: Int }) => Unit
  highlightLocation: (location) ->
    start = @_editor.posFromIndex(location.start)
    end   = @_editor.posFromIndex(location.end)
    @_editor.setSelection(start, end)
    @_editor.focus()
    return

  # () => Unit
  jumpToProcedure: () ->
    procInfo = @get('jumpToProcedure')
    if procInfo? and @_editor?
      @highlightProcedure(procInfo.procName, procInfo.index)
    return

  # () => Unit
  jumpToCode: () ->
    location = @get('jumpToCode')
    if location? and @_editor?
      @highlightLocation(location)
    return

})

RactiveCodeContainerOneLine = RactiveCodeContainerBase.extend({

  oncomplete: ->
    @._super()
    forceOneLine =
      (_, change) ->
        lines = if change.text[change.text.length - 1] is ''
          change.text.slice(0, change.text.length - 1)
        else
          change.text
        oneLineText = lines.join(' ')
        change.update(change.from, change.to, [oneLineText])
        true
    @_editor.on('beforeChange', forceOneLine)

    # Single-line inputs should navigate focus with Tab/Shift-Tab like a
    # regular <input> element, not insert a tab character.
    focusableSelector = [
      'a[href]'
      'button:not([disabled])'
      'input:not([disabled])'
      'select:not([disabled])'
      'textarea:not([disabled])'
      '[tabindex]:not([tabindex="-1"])'
      '.CodeMirror'
    ].join(', ')

    navigateFocus = (direction) =>
      wrapper    = @_editor.getWrapperElement()
      # Exclude elements nested inside a .CodeMirror wrapper (e.g. CodeMirror's
      # hidden textarea, which has tabindex="0" and would otherwise appear as
      # the very next focusable element after the wrapper itself).
      focusables = Array.from(document.querySelectorAll(focusableSelector))
        .filter((el) -> el.closest('.CodeMirror') is null or el.classList.contains('CodeMirror'))
      idx        = focusables.indexOf(wrapper)
      target     = focusables[idx + direction]
      if target?
        if target.CodeMirror?
          target.CodeMirror.focus()
        else
          target.focus()

    @_editor.addKeyMap({
      'Tab':       => navigateFocus(1)
      'Shift-Tab': => navigateFocus(-1)
    })

    return

})

# (Ractive) => Ractive
editFormCodeContainerFactory =
  (container) ->
    Ractive.extend({

      data: -> {
        config:        undefined # Object
      , id:            undefined # String
      , isCollapsible: false     # Boolean
      , isDisabled:    false     # Boolean
      , isExpanded:    undefined # Boolean
      , label:         undefined # String
      , onchange:      (->)      # (String) => Unit
      , style:         undefined # String
      , value:         undefined # String
      }

      twoway: false

      computed: {
        code: -> @findComponent('codeContainer').get('code')
      }

      components: {
        codeContainer: container
      }

      on: {

        init: ->

          isExpanded = @get('isExpanded') ? not @get('isCollapsible')
          @set('isExpanded', isExpanded)

          # If a CodeMirror instance is rendered invisibly, it displays and interacts
          # kinda funkily, once made visible, until you click it a couple of times.
          # In order to get it set up properly, we need to call its `refresh`
          # method, but we need to wait until Ractive has actually updated the GUI
          # to render the CodeMirror instance, first.
          #
          # Thus: This nonsense. --Jason B. (6/16/22)
          @observe('isExpanded', (newValue, oldValue) ->
            if newValue is true and oldValue is false
              setTimeout((=> @findComponent('codeContainer').refresh()), 0)
          )

          return

        "toggle-expansion": ->
          if @get("isCollapsible")
            @set("isExpanded", not @get("isExpanded"))
          false

      }

      template:
        """
        <div class="flex-row code-container-label{{#isExpanded}} open{{/}}"
             on-click="toggle-expansion">
          {{# isCollapsible }}
            <div for="{{id}}-is-expanded" class="expander widget-edit-checkbox-wrapper">
              <span id="{{id}}-is-expanded" class="widget-edit-input-label expander-label">&#9654;</span>
            </div>
          {{/}}
          <label for="{{id}}" class="expander-text">{{label}}</label>
        </div>
        <div class="{{# isCollapsible && !isExpanded }}hidden{{/}}" style="{{style}}">
          <codeContainer id="{{id}}" initialCode="{{value}}" injectedConfig="{{config}}"
                         isDisabled="{{isDisabled}}" onchange="{{onchange}}" />
        </div>
        """

    })

RactiveEditFormOneLineCode   = editFormCodeContainerFactory(RactiveCodeContainerOneLine)
RactiveEditFormMultilineCode = editFormCodeContainerFactory(RactiveCodeContainerMultiline)

export {
  RactiveCodeContainerMultiline,
  RactiveCodeContainerOneLine,
  RactiveEditFormOneLineCode,
  RactiveEditFormMultilineCode,
}
