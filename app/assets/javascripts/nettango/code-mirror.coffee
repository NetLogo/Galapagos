window.RactiveCodeMirror = Ractive.extend({
  data: () -> {
    id:          ""        # String
    mode:        "netlogo" # "netlogo" | "json" | "css"
    code:        ""        # String
    initialCode: ""        # String
    config:      undefined # CodeMirrorConfig
    newCode:     ""        # String
    isDirty:     false     # Boolean
  }

  on: {

    # (Context) => Unit
    'render': (_) ->
      @set('initialCode', @get('code'))

      mode = switch @get('mode')
        when 'json' then { name: 'javascript', json: true }
        when 'netlogo' then 'netlogo'
        when 'css' then 'css'
        else 'netlogo'

      baseConfig = { mode: mode, theme: 'netlogo-default', value: @get('code') }
      config     = Object.assign({}, baseConfig, @get('config') ? {})
      element    = @find("##{@get('id')}")
      editor     = new CodeMirror(element, config)

      editor.on('change', () =>
        initialCode = @get('initialCode')
        code = editor.getValue()
        @set('code', code)
        @set('isDirty', code isnt initialCode)
        return
      )

      onCodeSet = (initialCode) =>
        if (initialCode is undefined or initialCode is null) then return
        @set('isDirty', false)
        code = editor.getValue()
        if (code isnt initialCode)
          @set('initialCode', initialCode)
          editor.setValue(initialCode)
        return

      @observe('code', onCodeSet)

      return
  }

  template: """<div id={{ id }} class="ntb-code-mirror {{(extraClasses || []).join(' ')}}" />"""

})
