RactiveCodeMirror = Ractive.extend({
  data: () -> {
    id:             ""        # String
    mode:           "netlogo" # "netlogo" | "json" | "css"
    code:           ""        # String
    initialCode:    ""        # String
    config:         undefined # CodeMirrorConfig
    extraClasses:   []        # Array[String]
    multilineClass: undefined # String
    newCode:        ""        # String
    isDirty:        false     # Boolean
  }

  computed: {
    classes: () ->
      extraClasses = @get('extraClasses')
      multilineClass = @get('multilineClass')
      if multilineClass? and multilineClass isnt ''
        code = @get('code')
        if code? and code.includes('\n')
          extraClasses.push(multilineClass)
      extraClasses.join(' ')
  }

  on: {

    # (Context) => Unit
    'render': (_) ->
      @set('initialCode', @get('code'))

      mode = switch @get('mode')
        when 'json'    then { name: 'javascript', json: true }
        when 'netlogo' then 'netlogo'
        when 'css'     then 'css'
        else 'netlogo'

      baseConfig = { mode: mode, theme: 'netlogo-default', value: @get('code') ? '' }
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

  template: """<div id={{ id }} class="ntb-code-mirror {{classes}}" translate="no" />"""

})

export default RactiveCodeMirror
