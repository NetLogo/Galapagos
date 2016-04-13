RactiveCodeContainerBase = Ractive.extend({

  data: -> {
    code:             undefined # String
  , extraAttrs:       undefined # String
  , extraClasses:     undefined # String
  , extraConfig:      undefined # Object
  , injectedClasses:  undefined # String
  , injectedConfig:   undefined # Object
  , id:               undefined # String
  , isStale:          undefined # Boolean
  , lastCompiledCode: undefined # String
  }

  oncomplete: ->
    @_setupCodeMirror()

  isolated: true

  twoway: false

  _setupCodeMirror: ->

      baseConfig = { mode:  'netlogo', theme: 'netlogo-default' }
      config     = Object.assign({}, baseConfig, @get('extraConfig') ? {}, @get('injectedConfig') ? {})
      editor     = CodeMirror.fromTextArea(@find("##{@get('id')}"), config)

      editor.getDoc().setValue(@get('code'))

      editor.on('change', =>
        newCode = editor.getValue()
        @set('isStale', @get('lastCompiledCode') isnt newCode)
        @set('code',    newCode)
      )

      @on('teardown'
      , ->
          editor.toTextArea()
      )

  template:
    """
    <textarea id="{{id}}" class="{{extraClasses}} {{injectedClasses}}" {{extraAttrs}}></textarea>
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
