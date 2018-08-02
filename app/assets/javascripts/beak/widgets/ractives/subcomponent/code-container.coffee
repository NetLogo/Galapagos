RactiveCodeContainerBase = Ractive.extend({

  _editor: undefined # CodeMirror

  data: -> {
    code:           undefined # String
  , extraClasses:   undefined # Array[String]
  , extraConfig:    undefined # Object
  , id:             undefined # String
  , initialCode:    undefined # String
  , isDisabled:     false
  , injectedConfig: undefined # Object
  , onchange:       (->)      # (String) => Unit
  , style:          undefined # String
  }

  # An astute observer will ask what the purpose of `initialCode` is--why wouldn't we just make it
  # equivalent to `code`?  It's a good (albeit maddening) question.  Ractive does some funny stuff
  # if the code that comes in is the same as what is getting hit by `set` in the editor's on-change
  # event.  Basically, even though we explicitly say all over the place that we don't want to be
  # doing two-way binding, that `set` call will change the value here and everywhere up the chain.
  # So, to avoid that, `initialCode` is a dummy variable, and we dump it into `code` as soon as
  # reasonably possible.  --JAB (5/2/16)
  oncomplete: ->
    initialCode = @get('initialCode')
    @set('code', initialCode ? @get('code') ? "")
    @_setupCodeMirror()
    return

  twoway: false

  _setupCodeMirror: ->

    baseConfig = { mode: 'netlogo', theme: 'netlogo-default', value: @get('code').toString(), viewportMargin: Infinity }
    config     = Object.assign({}, baseConfig, @get('extraConfig') ? {}, @get('injectedConfig') ? {})
    @_editor   = new CodeMirror(@find("##{@get('id')}"), config)

    @_editor.on('change', =>
      code = @_editor.getValue()
      @set('code', code)
      @parent.fire('code-changed', code)
      @get('onchange')(code)
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

  # (String) => Unit
  setCode: (code) ->
    str = code.toString()
    if @_editor? and @_editor.getValue() isnt str
      @_editor.setValue(str)
    return

  template:
    """
    <div id="{{id}}" class="netlogo-code {{(extraClasses || []).join(' ')}}" style="{{style}}"></div>
    """

})

window.RactiveCodeContainerMultiline = RactiveCodeContainerBase.extend({

  data: -> {
    extraConfig: {
      tabSize: 2
      extraKeys: {
        "Ctrl-F": "findPersistent"
        "Cmd-F":  "findPersistent"
      }
    }
  }

  highlightProcedure: (procedureName, index) ->
    end   = @_editor.posFromIndex(index)
    start = CodeMirror.Pos(end.line, end.ch - procedureName.length)
    @_editor.setSelection(start, end)
    return

  getEditor: ->
    @_editor

})

window.RactiveCodeContainerOneLine = RactiveCodeContainerBase.extend({

  oncomplete: ->
    @._super()
    forceOneLine =
      (_, change) ->
        oneLineText = change.text.join('').replace(/\n/g, '')
        change.update(change.from, change.to, [oneLineText])
        true
    @_editor.on('beforeChange', forceOneLine)
    return

})

# (Ractive) => Ractive
editFormCodeContainerFactory =
  (container) ->
    Ractive.extend({

      data: -> {
        config:   undefined # Object
      , id:       undefined # String
      , label:    undefined # String
      , onchange: (->)      # (String) => Unit
      , style:    undefined # String
      , value:    undefined # String
      }

      twoway: false

      components: {
        codeContainer: container
      }

      template:
        """
        <label for="{{id}}">{{label}}</label>
        <codeContainer id="{{id}}" initialCode="{{value}}" injectedConfig="{{config}}"
                       onchange="{{onchange}}" style="{{style}}" />
        """

    })

window.RactiveEditFormOneLineCode   = editFormCodeContainerFactory(RactiveCodeContainerOneLine)
window.RactiveEditFormMultilineCode = editFormCodeContainerFactory(RactiveCodeContainerMultiline)
