RactiveCodeContainerBase = Ractive.extend({

  data: -> {
    code:             undefined # String
  , extraClasses:     undefined # String
  , extraConfig:      undefined # Object
  , injectedClasses:  undefined # String
  , injectedConfig:   undefined # Object
  , id:               undefined # String
  , isStale:          undefined # Boolean
  , lastCompiledCode: undefined # String
  }

  onrender: ->
    baseConfig = { value: @get('code'), mode:  'netlogo', theme: 'netlogo-default' }
    config     = Object.assign(baseConfig, @get('extraConfig') ? {}, @get('injectedConfig') ? {})
    editor     = CodeMirror(@find("##{@get('id')}"), config)
    editor.on('change', =>
      newCode = editor.getValue()
      @set('isStale', @get('lastCompiledCode') isnt newCode)
      @set('code',    newCode)
    )

  isolated: true

  twoway: false

  template:
    """
    <div id="{{id}}" class="netlogo-code {{extraClasses}} {{injectedClasses}}"></div>
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
