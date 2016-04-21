RactiveCodeContainerBase = Ractive.extend({

  data: -> {
    code:             undefined # String
  , extraClasses:     undefined # Array[String]
  , extraConfig:      undefined # Object
  , id:               undefined # String
  , injectedConfig:   undefined # Object
  , isStale:          undefined # Boolean
  , lastCompiledCode: undefined # String
  }

  oncomplete: ->
    @_setupCodeMirror()

  isolated: true

  twoway: false

  _setupCodeMirror: ->

      baseConfig = { mode:  'netlogo', theme: 'netlogo-default', value: @get('code'), viewportMargin: Infinity }
      config     = Object.assign({}, baseConfig, @get('extraConfig') ? {}, @get('injectedConfig') ? {})
      editor     = new CodeMirror(@find("##{@get('id')}"), config)

      editor.on('change', =>
        newCode = editor.getValue()
        @set('isStale', @get('lastCompiledCode') isnt newCode)
        @set('code',    newCode)
      )

      return

  template:
    """
    <div id="{{id}}" class="netlogo-code {{(extraClasses || []).join(' ')}}"></div>
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

  isolated: true

})

# INCOMPLETE
#window.RactiveCodeContainerSingleLine = RactiveCodeContainerBase.extend({
#
#  data: -> {
#    extraClasses: "single-line"
#  }
#
#  isolated: true
#
#})
