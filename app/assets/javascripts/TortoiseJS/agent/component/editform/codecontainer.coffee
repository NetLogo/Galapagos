RactiveCodeContainerBase = Ractive.extend({

  _editor: undefined # CodeMirror

  data: -> {
    code:           undefined # String
  , extraClasses:   undefined # Array[String]
  , extraConfig:    undefined # Object
  , id:             undefined # String
  , initialCode:    undefined # String
  , injectedConfig: undefined # Object
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
    if initialCode? then @set('code', initialCode)
    @_setupCodeMirror()

  twoway: false

  _setupCodeMirror: ->
    baseConfig = { mode:  'netlogo', theme: 'netlogo-default', value: @get('code'), viewportMargin: Infinity }
    config     = Object.assign({}, baseConfig, @get('extraConfig') ? {}, @get('injectedConfig') ? {})
    @_editor   = new CodeMirror(@find("##{@get('id')}"), config)
    @_editor.on('change', => @set('code', @_editor.getValue()))
    return

  # (String) => Unit
  setCode: (code) ->
    @_editor.setValue(code)
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

})

window.RactiveEditFormCodeContainer = Ractive.extend({

  data: -> {
    config: undefined # Object
  , id:     undefined # String
  , label:  undefined # String
  , style:  undefined # String
  , value:  undefined # String
  }

  twoway: false

  components: {
    codeContainer: RactiveCodeContainerMultiline
  }

  template:
    """
    <label for="{{id}}">{{label}}</label>
    <codeContainer id="{{id}}" initialCode="{{value}}" injectedConfig="{{config}}" style="{{style}}" />
    """

})
